// ISO 原盘(BDMV ISO)原生直连:
// 1. 自定义块读取回调把 libudfread 的 UDF 卷读翻译成对远端
//    Emby/Jellyfin 静态流的 HTTP Range 请求(POSIX socket,连接缓存)
// 2. 本地 127.0.0.1 HTTP 服务把 BDMV/STREAM 里的正片 m2ts 以普通
//    m2ts 网络流(支持 Range/206)暴露给播放内核
//
// 解码由播放内核原生完成(MPV 全量内核: HEVC/TrueHD/PGS 全支持);
// 本文件只做"字节搬运 + 文件系统解析"。

#define _GNU_SOURCE // strcasestr
#include <jni.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <pthread.h>
#include <poll.h>
#include <fcntl.h>
#include <time.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <android/log.h>

#include "iso_readahead.h"
#include "iso_http_range.h"
#include "libudfread/udfread.h"
#include "libudfread/blockinput.h"

#define LOG_TAG "IsoNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ============ 远端 ISO 的 HTTP Range 读取(单连接缓存 + 互斥) ============

typedef struct {
    char host[256];
    char port[8];
    char path[1400];
    int sock;             // -1 = 未连接
    uint64_t total;       // 远端总字节数(由 Content-Range 校准,0=未知)
    pthread_mutex_t lock;
} iso_http;

static iso_http g_http = { .sock = -1, .total = 0 };
static udfread *g_udf = NULL;
static char g_m2ts_path[512];
static uint64_t g_m2ts_size = 0;
static int g_listen_fd = -1;
static int g_server_port = 0;
static volatile int g_run = 0;

// ============ 顺序预读窗口 ============
//
// 旧实现：本地服务每 32KB 就发一次远端 Range 请求 —— 44Mbps 需要约 172 次/秒，
// 吞吐被钉死在「32KB ÷ 每请求延迟」上。真机实证：5GHz 链路单流实测 193MB/s，
// 但原盘仍周期性卡顿，就是被这个粒度拖住的。
// 窗口把远端抓取放大到 4MB（请求数降两个数量级），并预取 2 块（8MB）吸收单次
// 抓取延迟。决策逻辑在 iso_readahead.h（有宿主单测），这里只做 IO 与线程。
static const uint64_t kRaBlockBytes = 4ull * 1024 * 1024;
static const int kRaSlots = 4;            // 4 槽 = 16MB 上限（含 2 块预取）
static const int kRaLookahead = 2;
// 远端单次请求超时：超时即重连重试，避免一次抖动就永久阻塞(持锁)
static const int kHttpTimeoutSec = 10;

// 正片片段缓存：同一个条目再次打开时不必重扫 STREAM 下每个 m2ts。
// 真机实证（2026-09-27）：139 片段的原盘，每条目一次远端读 ≈100ms，
// 全量扫描要十几秒（此前还因此把主线程卡到 ANR）。
// 键用静态流的 URL 路径（形如 /Videos/{itemId}/stream），它按条目稳定，
// 而查询串里的 PlaySessionId 每次播放都会变。
struct clip_cache_entry {
    char url_path[1400];
    char m2ts_path[512];
    uint64_t size;
};
static clip_cache_entry g_clip_cache[4];
static int g_clip_cache_n = 0;

static clip_cache_entry *clip_cache_lookup(const char *url_path) {
    for (int i = 0; i < g_clip_cache_n; i++) {
        if (strcmp(g_clip_cache[i].url_path, url_path) == 0) return &g_clip_cache[i];
    }
    return NULL;
}

static void clip_cache_store(const char *url_path, const char *m2ts, uint64_t size) {
    if (!url_path || !url_path[0] || !m2ts || !m2ts[0]) return;
    int idx = g_clip_cache_n < 4 ? g_clip_cache_n++ : 0;  // 满了就覆盖第一个
    snprintf(g_clip_cache[idx].url_path, sizeof(g_clip_cache[idx].url_path), "%s", url_path);
    snprintf(g_clip_cache[idx].m2ts_path, sizeof(g_clip_cache[idx].m2ts_path), "%s", m2ts);
    g_clip_cache[idx].size = size;
    LOGI("正片片段已缓存（同一条目下次打开跳过扫描）");
}

static ReadAheadWindow g_ra(kRaBlockBytes, kRaSlots, kRaLookahead);
static uint8_t *g_ra_buf[kRaSlots] = {NULL};
// 窗口只在「卷已打开、缓冲已分配」后启用：打开 UDF 卷阶段的读又小又随机，
// 走窗口没有收益，却会在缓冲尚未分配时踩空（首版就是这么失败的）
static volatile int g_ra_ready = 0;
static pthread_mutex_t g_ra_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t g_ra_cv = PTHREAD_COND_INITIALIZER;
static uint64_t g_ra_prefetch_block = 0;
static int g_ra_prefetch_valid = 0;
static pthread_t g_ra_thread;
static int g_ra_thread_running = 0;
static uint64_t g_ra_fetches = 0;
static uint64_t g_ra_fetch_bytes = 0;

static int tcp_connect(const char *host, const char *port) {
    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    int fd = -1;
    if (getaddrinfo(host, port, &hints, &res) != 0) return -1;
    for (struct addrinfo *ai = res; ai; ai = ai->ai_next) {
        fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
        if (fd < 0) continue;
        // 非阻塞 connect + poll 限时：NAS 掉线时不再卡几十秒
        int flags = fcntl(fd, F_GETFL, 0);
        fcntl(fd, F_SETFL, flags | O_NONBLOCK);
        int r = connect(fd, ai->ai_addr, ai->ai_addrlen);
        if (r != 0 && errno == EINPROGRESS) {
            struct pollfd pfd;
            pfd.fd = fd;
            pfd.events = POLLOUT;
            pfd.revents = 0;
            r = poll(&pfd, 1, kHttpTimeoutSec * 1000);
            if (r > 0) {
                int err = 0;
                socklen_t elen = sizeof(err);
                getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &elen);
                r = (err == 0) ? 0 : -1;
            } else {
                r = -1;
            }
        } else if (r == 0) {
            r = 0;
        } else {
            r = -1;
        }
        fcntl(fd, F_SETFL, flags);
        if (r == 0) {
            struct timeval tv;
            tv.tv_sec = kHttpTimeoutSec;
            tv.tv_usec = 0;
            setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
            setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
            int one = 1;
            setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
            break;
        }
        close(fd);
        fd = -1;
    }
    freeaddrinfo(res);
    return fd;
}

static int recv_header(int sock, char *hdr, int hdr_cap) {
    int hpos = 0;
    while (hpos < hdr_cap - 1) {
        char ch;
        int n = recv(sock, &ch, 1, 0);
        if (n <= 0) return -1;
        hdr[hpos++] = ch;
        if (hpos >= 4 && hdr[hpos - 4] == '\r' && hdr[hpos - 3] == '\n' &&
            hdr[hpos - 2] == '\r' && hdr[hpos - 1] == '\n') {
            hdr[hpos] = 0;
            return hpos;
        }
    }
    return -1;
}

// 单次 Range 请求:读满 len 字节。成功 0,失败 -1
//
// 校验要点：
// - 状态行取码前先判空指针（无空格即崩）
// - 必须落到请求的偏移上：解析 Content-Range 的起始字节比对；
//   服务器忽略 Range 返回 200(整文件) 时直接失败 —— 否则字节会对不上
// - 顺带用 `bytes X-Y/TOTAL` 校准远端总大小（预读窗口要知道文件尾在哪）
//
// why/status_out 仅用于失败时把"卡在哪一步、服务器回了什么"带出去：
// 没有它就只能靠推断（实测踩过：240 条失败日志里没有一个字能说明原因）
static int http_request_once(uint64_t off, uint8_t *buf, uint32_t len,
                             const char **why, char *status_out,
                             size_t status_cap) {
    char req[1600];
    snprintf(req, sizeof(req),
             "GET %s HTTP/1.1\r\n"
             "Host: %s\r\n"
             "Range: bytes=%llu-%llu\r\n"
             "Accept: */*\r\n"
             "Connection: close\r\n\r\n",
             g_http.path, g_http.host,
             (unsigned long long)off,
             (unsigned long long)(off + (len ? len - 1 : 0)));
    if (send(g_http.sock, req, strlen(req), 0) != (ssize_t)strlen(req)) {
        *why = "send";
        return -1;
    }

    char hdr[4096];
    int hlen = recv_header(g_http.sock, hdr, sizeof(hdr));
    if (hlen < 0) {
        *why = "header";
        return -1;
    }
    if (status_out && status_cap > 0) {
        size_t n = 0;
        for (; n + 1 < status_cap && hdr[n] && hdr[n] != '\r'; n++) status_out[n] = hdr[n];
        status_out[n] = 0;
    }
    if (strncmp(hdr, "HTTP/1.", 7) != 0) {
        *why = "proto";
        return -1;
    }
    const char *sp = strchr(hdr, ' ');
    if (!sp) {
        *why = "status";
        return -1;
    }
    int status = atoi(sp + 1);

    // Content-Range 解析交给 iso_http_range.h（有宿主单测）：各家写法不一，
    // 尤其冒号后可能没有空格（Emby 就是这种），这里已经栽过一次 ——
    // 240 条请求全被判「偏移不符」，因为 strtoull 停在 'b' 上得 0
    const char *cr = strcasestr(hdr, "content-range:");
    if (cr) {
        ContentRange r;
        if (!parseContentRange(cr + 14, &r)) {
            *why = "range";
            return -1;
        }
        if (r.start != off) { // 服务器给的不是我们要的偏移
            *why = "range-off";
            return -1;
        }
        if (r.total > 0) g_http.total = r.total;
        if (status_out && status_cap > 0) { // 诊断：把 Content-Range 也带上
            size_t used = strlen(status_out);
            if (used + 4 < status_cap) {
                status_out[used++] = ' ';
                status_out[used++] = '|';
                status_out[used++] = ' ';
                size_t i = 0;
                for (; i + used + 1 < status_cap && cr[14 + i] && cr[14 + i] != '\r';
                     i++) {
                    status_out[used + i] = cr[14 + i];
                }
                status_out[used + i] = 0;
            }
        }
    }
    if (status != 206 && !(status == 200 && off == 0)) {
        *why = "status";
        return -1;
    }
    if (status == 200) g_http.total = 0; // 200=未按 Range 返回，尺寸别乱信

    // 头缓冲里可能已带出部分 body
    const char *body_at = strstr(hdr, "\r\n\r\n");
    if (!body_at) {
        *why = "hdr-end";
        return -1;
    }
    body_at += 4;
    long have = hlen - (int)(body_at - hdr);
    if (have > (long)len) have = len;
    if (have > 0) memcpy(buf, body_at, have);

    uint32_t got = (uint32_t)have;
    while (got < len) {
        int n = recv(g_http.sock, buf + got, len - got, 0);
        if (n <= 0) { // 超时/断开 → 上层重连重试
            *why = (n == 0) ? "body-eof" : "body-recv";
            return -1;
        }
        got += n;
    }
    *why = "ok";
    return 0;
}

static int http_read_range(uint64_t off, uint8_t *buf, uint32_t len) {
    pthread_mutex_lock(&g_http.lock);
    const char *why = "-";
    int last_errno = 0;
    char status[192];
    status[0] = 0;
    for (int attempt = 0; attempt < 2; attempt++) {
        if (g_http.sock < 0) {
            g_http.sock = tcp_connect(g_http.host, g_http.port);
            if (g_http.sock < 0) {
                why = "connect";
                last_errno = errno;
                continue;
            }
        }
        if (http_request_once(off, buf, len, &why, status, sizeof(status)) == 0) {
            // 连接复用与否要分两种情形（真机实测）：
            //   - 小读（UDF 元数据，2KB）：开 ISO 时要连做上百次，**必须复用**。
            //     一请求一连接在 Emby 上每次约 50ms、复用连接约 10ms —— 139 片段的
            //     原盘因此从 1 秒级膨胀到 15 秒级，直接把主线程拖到 ANR。
            //   - off==0 的探针：服务器可能忽略 Range 回 200（整文件），我们只读走
            //     16 字节、body 剩下的会污染下一条响应 → 这一种必须关连接。
            //   - 读到大块（4MB）：每 ~1 秒才一次，复用与否无所谓，照旧复用。
            // 只有 off==0 需要关：校验规则里只有它是唯一允许 200（整文件）的情形
            // （见 http_request_once 的状态判断），其余请求必定是 206 且长度精确，
            // 连接天然同步，可安全复用。
            if (off == 0) {
                close(g_http.sock);
                g_http.sock = -1;
            }
            pthread_mutex_unlock(&g_http.lock);
            return 0;
        }
        last_errno = errno;
        close(g_http.sock);
        g_http.sock = -1;
    }
    pthread_mutex_unlock(&g_http.lock);
    // 直读失败以前完全静默 —— 排查"打不开/卡住"时看不到任何线索
    LOGW("远端直读失败: off=%llu len=%u 步骤=%s 状态=[%s] errno=%d",
         (unsigned long long)off, len, why, status, last_errno);
    return -1;
}

// ============ 预读：把远端抓取放大到 4MB ============

/// 分配预读槽位缓冲并启用窗口。失败返回 false（不启用，退回直读）。
static bool ra_setup() {
    g_ra.reset();
    for (int i = 0; i < kRaSlots; i++) {
        if (g_ra_buf[i]) continue;  // 复用已分配的
        g_ra_buf[i] = (uint8_t *)malloc((size_t)kRaBlockBytes);
        if (!g_ra_buf[i]) {
            for (int j = 0; j < kRaSlots; j++) {
                free(g_ra_buf[j]);
                g_ra_buf[j] = NULL;
            }
            return false;
        }
    }
    g_ra_prefetch_valid = 0;
    g_ra_fetches = 0;
    g_ra_fetch_bytes = 0;
    g_ra_ready = 1;
    return true;
}

/// 一次抓取（长度会被远端总大小夹住）。返回 true=装满了 dst 的前 len 字节。
static bool ra_fetch_into(uint64_t block, uint8_t *dst) {
    uint64_t off = block * kRaBlockBytes;
    size_t len = (size_t)kRaBlockBytes;
    // 32 位下 uint64 读取非原子：取一次快照，避免同一次调用里前后值不一致
    const uint64_t total = g_http.total;
    if (total > 0) {
        if (off >= total) return false;
        if (off + len > total) len = (size_t)(total - off);
    }
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    bool ok = http_read_range(off, dst, (uint32_t)len) == 0;
    clock_gettime(CLOCK_MONOTONIC, &t1);
    long ms = (long)((t1.tv_sec - t0.tv_sec) * 1000 +
                     (t1.tv_nsec - t0.tv_nsec) / 1000000);
    pthread_mutex_lock(&g_ra_lock);
    g_ra_fetches++;
    if (ok) g_ra_fetch_bytes += len;
    uint64_t n = g_ra_fetches;
    double mb = g_ra_fetch_bytes / 1048576.0;
    pthread_mutex_unlock(&g_ra_lock);
    LOGI("远端抓取 #%llu: block=%llu off=%llu len=%zu %s 用时 %ldms（累计 %.1fMB）",
         (unsigned long long)n, (unsigned long long)block,
         (unsigned long long)off, len, ok ? "OK" : "失败", ms, mb);
    return ok;
}

/// 预取线程：只在有目标时抓取；目标块越过文件尾则跳过
static void *ra_prefetch_thread(void *arg) {
    (void)arg;
    while (g_run) {
        pthread_mutex_lock(&g_ra_lock);
        while (g_run && !g_ra_prefetch_valid) {
            struct timespec ts;
            clock_gettime(CLOCK_REALTIME, &ts);
            ts.tv_sec += 1; // 1 秒轮询：兼顾响应与空转
            pthread_cond_timedwait(&g_ra_cv, &g_ra_lock, &ts);
        }
        if (!g_run) {
            pthread_mutex_unlock(&g_ra_lock);
            break;
        }
        uint64_t block = g_ra_prefetch_block;
        g_ra_prefetch_valid = 0;
        bool beyond_end = g_http.total > 0 &&
                          (block + 1) * kRaBlockBytes > g_http.total;
        if (beyond_end || g_ra.isResident(block) || g_ra.isFetching(block)) {
            pthread_mutex_unlock(&g_ra_lock);
            continue;
        }
        int slot = g_ra.acquireSlot(block);
        uint8_t *dst = slot >= 0 ? g_ra_buf[slot] : NULL;
        pthread_mutex_unlock(&g_ra_lock);
        if (!dst) continue;

        bool ok = ra_fetch_into(block, dst);

        pthread_mutex_lock(&g_ra_lock);
        if (ok) {
            g_ra.markResident(block);
        } else {
            g_ra.markFailed(block);
        }
        pthread_cond_broadcast(&g_ra_cv);
        pthread_mutex_unlock(&g_ra_lock);
    }
    return NULL;
}

/// 窗口读：命中直接拷；未命中先抓整块（同一块的后续读全部命中）
static ssize_t ra_read(uint64_t off, uint8_t *buf, size_t len) {
    size_t done = 0;
    int waits = 0;
    while (done < len) {
        uint64_t cur = off + done;
        uint64_t block = g_ra.blockOf(cur);
        size_t in_block = (size_t)(cur - block * kRaBlockBytes);
        size_t chunk = (size_t)kRaBlockBytes - in_block;
        if (chunk > len - done) chunk = len - done;

        pthread_mutex_lock(&g_ra_lock);
        if (!g_ra.isResident(block) && !g_ra.isFetching(block)) {
            int slot = g_ra.acquireSlot(block);
            uint8_t *dst = slot >= 0 ? g_ra_buf[slot] : NULL;
            if (!dst) {
                // 缓冲不可用（不该发生：窗口只在分配完成后启用）——
                // 立刻失败让上层走直读，绝不在这里打转（首版就是在这里转死的）
                pthread_mutex_unlock(&g_ra_lock);
                LOGE("预读缓冲不可用(slot=%d, block=%llu)：回退直读", slot,
                     (unsigned long long)block);
                return -1;
            }
            pthread_mutex_unlock(&g_ra_lock);
            bool ok = ra_fetch_into(block, dst);
            pthread_mutex_lock(&g_ra_lock);
            if (ok) {
                g_ra.markResident(block);
            } else {
                g_ra.markFailed(block);
            }
            pthread_cond_broadcast(&g_ra_cv);
            pthread_mutex_unlock(&g_ra_lock);
            if (!ok) {
                LOGW("窗口抓取失败: block=%llu（上层将回退直读）",
                     (unsigned long long)block);
                return -1;
            }
            continue;
        }
        if (g_ra.isFetching(block)) {
            // 另一线程正在抓同一块：等它结束（抓取失败也会广播）。
            // 等待有上限：万一抓取方卡住，也要回退直读而不是陪它卡到天荒地老
            if (waits++ >= 5) {
                pthread_mutex_unlock(&g_ra_lock);
                LOGE("等待预读块超时(block=%llu)：回退直读",
                     (unsigned long long)block);
                return -1;
            }
            struct timespec ts;
            clock_gettime(CLOCK_REALTIME, &ts);
            ts.tv_sec += 1;
            pthread_cond_timedwait(&g_ra_cv, &g_ra_lock, &ts);
            pthread_mutex_unlock(&g_ra_lock);
            continue;
        }
        int slot = g_ra.slotOf(block);
        uint8_t *src = slot >= 0 ? g_ra_buf[slot] : NULL;
        if (!src) {
            pthread_mutex_unlock(&g_ra_lock);
            return -1;
        }
        // 在锁内拷贝：避免拷贝途中槽位被预取线程淘汰
        memcpy(buf + done, src + in_block, chunk);
        uint64_t target = 0;
        if (g_ra.onServed(cur, chunk, &target)) {
            g_ra_prefetch_block = target;
            g_ra_prefetch_valid = 1;
            pthread_cond_broadcast(&g_ra_cv);
        }
        pthread_mutex_unlock(&g_ra_lock);
        done += chunk;
    }
    return (ssize_t)done;
}

// ============ libudfread 块读取回调 ============

static int bi_close(udfread_block_input *bi) {
    (void)bi;
    return 0;
}

static int bi_read(udfread_block_input *bi, uint32_t lba, void *buf,
                   uint32_t nblocks, int flags) {
    (void)bi;
    (void)flags;
    uint64_t off = (uint64_t)lba * 2048;
    uint32_t total = nblocks * 2048;
    if (total == 0) return 0;

    // 小读（UDF 元数据 2KB）也走窗口：直读的话每次一个小请求，在 Emby 上
    // 每请求 100~200ms，几十次就是秒级；走窗口会把该区域一次拉 4MB，
    // 后续同区元数据全部命中（UDF 元数据成簇分布，这笔数据本来也要读）。
    // 只有文件尾的残块直读（窗口只装整块）。
    bool tail_block = g_http.total > 0 &&
                      (g_ra.blockOf(off) + 1) * kRaBlockBytes > g_http.total;
    if (!g_ra_ready || tail_block) {
        if (http_read_range(off, (uint8_t *)buf, total) != 0) return 0;
        return (int)nblocks;
    }

    if (ra_read(off, (uint8_t *)buf, total) == (ssize_t)total) {
        return (int)nblocks;
    }
    // 窗口失败（远端抖动等）：退回直读，别让一次失败打断播放
    if (http_read_range(off, (uint8_t *)buf, total) != 0) return 0;
    return (int)nblocks;
}

static uint32_t bi_size(udfread_block_input *bi) {
    (void)bi;
    return 0; // 未知:libudfread 以卷描述符自行判定
}

static struct udfread_block_input g_block_input = {
    .close = bi_close,
    .read  = bi_read,
    .size  = bi_size,
};

// udfread_open(path) 的本地文件块输入我们不用(ISO 在远端);
// 该符号被 udfread.c 引用,链器要求必须存在,给个空桩。
extern "C" udfread_block_input *block_input_new(const char *path) {
    (void)path;
    return NULL;
}

// ============ BDMV/STREAM 最大 m2ts 查找 ============

static int find_largest_m2ts(char *path_out, size_t path_out_len,
                             uint64_t *size_out) {
    UDFDIR *dir = udfread_opendir(g_udf, "/BDMV/STREAM");
    if (!dir) {
        LOGW("无法打开 /BDMV/STREAM");
        return -1;
    }
    struct udfread_dirent entry;
    char best[512] = "";
    uint64_t best_size = 0;
    while (udfread_readdir(dir, &entry)) {
        const char *name = entry.d_name;
        size_t len = strlen(name);
        if (len < 5 || strcasecmp(name + len - 5, ".M2TS") != 0) continue;
        char path[600];
        snprintf(path, sizeof(path), "/BDMV/STREAM/%s", name);
        UDFFILE *f = udfread_file_open(g_udf, path);
        if (!f) continue;
        uint64_t sz = (uint64_t)udfread_file_size(f);
        udfread_file_close(f);
        LOGI("发现 m2ts: %s (%llu bytes)", path, (unsigned long long)sz);
        if (sz > best_size) {
            best_size = sz;
            snprintf(best, sizeof(best), "%s", path);
        }
        // 蓝光正片必然 ≥20GB（花絮/菜单不会到这个量级）→ 命中即可收工，
        // 省掉后面几十上百次远端读（139 片段的原盘扫完要十几秒）
        if (best_size >= (20ull << 30)) {
            LOGI("已找到 ≥20GB 的正片，跳过剩余片段扫描");
            break;
        }
    }
    udfread_closedir(dir);
    if (best[0] == 0 || best_size == 0) {
        LOGW("STREAM 下无有效 m2ts");
        return -1;
    }
    snprintf(path_out, path_out_len, "%s", best);
    *size_out = best_size;
    return 0;
}

// ============ 本地 HTTP 服务(暴露正片 m2ts, Range/206) ============

static void serve_connection(int fd) {
    // 播放内核按 128KB 流缓冲来读，本地回包不做 Nagle 合并（少一次往返等待）
    int one = 1;
    setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));

    UDFFILE *f = udfread_file_open(g_udf, g_m2ts_path);
    if (!f) { close(fd); return; }

    char hdr[2048];
    int hpos = 0;
    while (hpos < (int)sizeof(hdr) - 1) {
        char ch;
        int n = recv(fd, &ch, 1, 0);
        if (n <= 0) { break; }
        hdr[hpos++] = ch;
        if (hpos >= 4 && hdr[hpos - 4] == '\r' && hdr[hpos - 3] == '\n' &&
            hdr[hpos - 2] == '\r' && hdr[hpos - 1] == '\n') break;
    }
    hdr[hpos] = 0;

    uint64_t start = 0;
    const char *range = strcasestr(hdr, "Range: bytes=");
    if (!range) range = strcasestr(hdr, "range: bytes=");
    if (range) {
        range += 13;
        unsigned long long a = 0;
        if (sscanf(range, "%llu", &a) == 1) start = a;
    }
    if (start >= g_m2ts_size) start = g_m2ts_size > 0 ? g_m2ts_size - 1 : 0;
    uint64_t end = g_m2ts_size - 1;

    char resp[512];
    snprintf(resp, sizeof(resp),
             "HTTP/1.1 206 Partial Content\r\n"
             "Content-Type: video/mp2t\r\n"
             "Accept-Ranges: bytes\r\n"
             "Content-Range: bytes %llu-%llu/%llu\r\n"
             "Content-Length: %llu\r\n"
             "Connection: close\r\n\r\n",
             (unsigned long long)start, (unsigned long long)end,
             (unsigned long long)g_m2ts_size,
             (unsigned long long)(end - start + 1));
    if (send(fd, resp, strlen(resp), MSG_NOSIGNAL) < 0) {
        udfread_file_close(f);
        close(fd);
        return;
    }

    udfread_file_seek(f, (int64_t)start, UDF_SEEK_SET);
    // 64KB/次：读的是预读窗口（命中即 memcpy），单次读大一些可少几次系统调用
    uint8_t buf[64 * 1024];
    uint64_t remaining = end - start + 1;
    while (remaining > 0 && g_run) {
        uint32_t want = remaining > sizeof(buf) ? sizeof(buf) : (uint32_t)remaining;
        ssize_t n = udfread_file_read(f, buf, want);
        if (n <= 0) break;
        ssize_t off = 0;
        while (off < n) {
            ssize_t s = send(fd, buf + off, n - off, MSG_NOSIGNAL);
            if (s <= 0) { remaining = 0; break; }
            off += s;
            remaining -= (uint64_t)s;
        }
    }
    udfread_file_close(f);
    close(fd);
}

static void *server_thread(void *arg) {
    (void)arg;
    while (g_run) {
        int fd = accept(g_listen_fd, NULL, NULL);
        if (fd < 0) break;
        pthread_t t;
        pthread_create(&t, NULL,
                       (void *(*)(void *))serve_connection,
                       (void *)(intptr_t)fd);
        pthread_detach(t);
    }
    return NULL;
}

// ============ 生命周期 ============

static void iso_shutdown(void) {
    g_run = 0;
    g_ra_ready = 0; // 先停用窗口：避免关片过程中还有读走窗口取到已释放的缓冲
    // 预取线程可能正阻塞在 recv 上：先广播唤醒，再 shutdown 直接打断，
    // 最后 join —— 否则关闭 ISO 要等满一个超时（最多 kHttpTimeoutSec 秒）
    pthread_mutex_lock(&g_ra_lock);
    g_ra_prefetch_valid = 0;
    pthread_cond_broadcast(&g_ra_cv);
    pthread_mutex_unlock(&g_ra_lock);
    if (g_http.sock >= 0) shutdown(g_http.sock, SHUT_RDWR);
    if (g_ra_thread_running) {
        pthread_join(g_ra_thread, NULL);
        g_ra_thread_running = 0;
    }
    if (g_listen_fd >= 0) { close(g_listen_fd); g_listen_fd = -1; }
    if (g_http.sock >= 0) { close(g_http.sock); g_http.sock = -1; }
    if (g_udf) { udfread_close(g_udf); g_udf = NULL; }
    // 缓冲释放前必须清空窗口：否则下次打开会把旧块号当常驻，读到垃圾
    g_ra.reset();
    for (int i = 0; i < kRaSlots; i++) {
        free(g_ra_buf[i]);
        g_ra_buf[i] = NULL;
    }
    g_http.total = 0;
    g_ra_fetches = 0;
    g_ra_fetch_bytes = 0;
    g_m2ts_size = 0;
    g_m2ts_path[0] = 0;
}

static int parse_url(const char *url, char *host, size_t host_len,
                     char *port, size_t port_len,
                     char *path, size_t path_len) {
    const char *p = strstr(url, "://");
    if (!p) return -1;
    p += 3;
    const char *slash = strchr(p, '/');
    if (!slash) return -1;
    const char *colon = (const char *)memchr(p, ':', (size_t)(slash - p));
    size_t hlen = colon ? (size_t)(colon - p) : (size_t)(slash - p);
    if (hlen >= host_len) return -1;
    memcpy(host, p, hlen);
    host[hlen] = 0;
    if (colon) {
        size_t plen = (size_t)(slash - colon - 1);
        if (plen >= port_len) return -1;
        memcpy(port, colon + 1, plen);
        port[plen] = 0;
    } else {
        snprintf(port, port_len, "80");
    }
    size_t pathlen = strlen(slash);
    if (pathlen >= path_len) return -1;
    memcpy(path, slash, pathlen + 1);
    return 0;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_lanplayer_IsoBridge_nativeOpenIso(JNIEnv *env, jclass clazz,
                                           jstring jUrl, jlong jSize) {
    (void)clazz;
    (void)jSize; // 总大小由首响应的 Content-Range 校准,不必预传
    const char *url = env->GetStringUTFChars(jUrl, NULL);
    if (!url) return NULL;

    if (parse_url(url, g_http.host, sizeof(g_http.host),
                  g_http.port, sizeof(g_http.port),
                  g_http.path, sizeof(g_http.path)) != 0) {
        env->ReleaseStringUTFChars(jUrl, url);
        LOGE("URL 解析失败");
        return NULL;
    }
    if (strncmp(g_http.host, url, 4) == 0) {} // no-op
    g_http.sock = -1;
    g_http.total = 0;
    env->ReleaseStringUTFChars(jUrl, url);

    // 首次 Range 探测:校验连通性(后续读取按需建连)
    uint8_t probe[16];
    if (http_read_range(0, probe, sizeof(probe)) != 0) {
        LOGE("无法访问远端 ISO 流");
        return NULL;
    }
    LOGI("远端探测 OK: 总大小 %llu bytes", (unsigned long long)g_http.total);

    // ── 预读窗口必须在打开 UDF 卷**之前**启用 ──
    // 开卷与扫描目录是几十次 2KB 小读，直读的话每次一个完整往返：真机实测
    // （2026-09-27，同一个 39.6GB 原盘）Emby 每次小读 100~200ms → 开卷 2107ms +
    // 扫描 1053ms，而 Jellyfin 只用 301ms + 119ms。走窗口后这些小读会合并成
    // 少数几次 4MB 抓取（UDF 元数据本就成簇分布），代价只是多读几 MB。
    if (!ra_setup()) {
        LOGE("预读缓冲分配失败");
        return NULL;
    }
    g_run = 1;
    if (pthread_create(&g_ra_thread, NULL, ra_prefetch_thread, NULL) == 0) {
        g_ra_thread_running = 1;
    } else {
        LOGW("预取线程启动失败：仍按 4MB 块同步抓取");
    }

    // ── 打开 UDF 卷（读走窗口）──
    g_udf = udfread_init();
    if (!g_udf) {
        LOGE("udfread_init 失败");
        iso_shutdown();
        return NULL;
    }
    if (udfread_open_input(g_udf, &g_block_input) != 0) {
        LOGE("udfread_open_input 失败");
        iso_shutdown();
        return NULL;
    }
    LOGI("UDF 卷已打开");

    struct timespec scan_t0, scan_t1;
    clock_gettime(CLOCK_MONOTONIC, &scan_t0);
    clip_cache_entry *cached = clip_cache_lookup(g_http.path);
    if (cached) {
        snprintf(g_m2ts_path, sizeof(g_m2ts_path), "%s", cached->m2ts_path);
        g_m2ts_size = cached->size;
        LOGI("正片(缓存命中,跳过扫描): %s (%llu bytes)", g_m2ts_path,
             (unsigned long long)g_m2ts_size);
    } else if (find_largest_m2ts(g_m2ts_path, sizeof(g_m2ts_path), &g_m2ts_size) != 0) {
        iso_shutdown();
        return NULL;
    } else {
        clock_gettime(CLOCK_MONOTONIC, &scan_t1);
        LOGI("正片: %s (%llu bytes)，全量扫描用时 %ldms", g_m2ts_path,
             (unsigned long long)g_m2ts_size,
             (long)((scan_t1.tv_sec - scan_t0.tv_sec) * 1000 +
                    (scan_t1.tv_nsec - scan_t0.tv_nsec) / 1000000));
        clip_cache_store(g_http.path, g_m2ts_path, g_m2ts_size);
    }

    LOGI("预读窗口已启用: %d×%lluMB（远端抓取放大 %llu 倍）", kRaSlots,
         (unsigned long long)(kRaBlockBytes / 1048576),
         (unsigned long long)(kRaBlockBytes / 32768));

    g_listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    int one = 1;
    setsockopt(g_listen_fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = 0;
    if (bind(g_listen_fd, (struct sockaddr *)&addr, sizeof(addr)) != 0 ||
        listen(g_listen_fd, 4) != 0) {
        LOGE("本地服务启动失败");
        udfread_close(g_udf);
        g_udf = NULL;
        return NULL;
    }
    socklen_t alen = sizeof(addr);
    getsockname(g_listen_fd, (struct sockaddr *)&addr, &alen);
    g_server_port = ntohs(addr.sin_port);

    pthread_t t;
    pthread_create(&t, NULL, server_thread, NULL);
    pthread_detach(t);

    char local[64];
    snprintf(local, sizeof(local), "http://127.0.0.1:%d/stream.m2ts", g_server_port);
    LOGI("ISO 直连就绪: %s", local);
    return env->NewStringUTF(local);
}

extern "C" JNIEXPORT void JNICALL
Java_com_lanplayer_IsoBridge_nativeCloseIso(JNIEnv *env, jclass clazz) {
    (void)env; (void)clazz;
    iso_shutdown();
}
