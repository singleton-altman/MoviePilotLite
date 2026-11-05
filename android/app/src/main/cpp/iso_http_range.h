// iso_http_range.h —— Content-Range 头解析（纯逻辑，可宿主单测）
//
// 为什么单独成文件：ISO 直连曾因为这里的一行假设整条链路瘫痪 —— 按
// `冒号位置 + 14` 直接取数字，隐含假设冒号后必有空格；而 Emby 回的是
// `Content-Range:bytes 0-2047/47526379520`（无空格），strtoull 停在 'b' 上
// 得到 0，于是除 off=0 的探针外，每个请求都被判成「偏移不符」并失败
// （真机 240 条失败日志，每条仅 ~20ms —— 快速失败而非超时）。
//
// 解析规则（容忍各家写法）：
//   可选空白 + 可选 "bytes"(大小写不敏感) + 可选空白 + 起始偏移 + "-" +
//   结束偏移 + "/" + (总长 或 "*")
// "bytes */TOTAL"（416 响应）没有可用起始偏移 → 返回 false。

#ifndef LANPLAYER_ISO_HTTP_RANGE_H
#define LANPLAYER_ISO_HTTP_RANGE_H

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <strings.h>  // strncasecmp（POSIX；bionic 与 MSYS2 都在这里）

struct ContentRange {
    uint64_t start = 0;
    uint64_t end = 0;
    uint64_t total = 0;  // 0 = 未知/通配(*)
};

/// @param value "content-range:" 冒号**之后**的部分（可带前导空白）
/// @return true = 解析出起始偏移（total 可能为 0）；false = 不可用
inline bool parseContentRange(const char *value, ContentRange *out) {
    if (!value || !out) return false;
    const char *p = value;
    while (*p == ' ' || *p == '\t') p++;
    if (strncasecmp(p, "bytes", 5) == 0) {
        p += 5;
        while (*p == ' ' || *p == '\t') p++;
    }
    if (*p < '0' || *p > '9') return false;  // 无起始偏移（含 "*/TOTAL"）

    char *endp = nullptr;
    unsigned long long start = strtoull(p, &endp, 10);
    if (!endp || *endp != '-') return false;
    const char *q = endp + 1;
    unsigned long long end = strtoull(q, &endp, 10);
    if (!endp || *endp != '/') return false;
    const char *t = endp + 1;
    unsigned long long total = 0;
    if (*t != '*') {
        total = strtoull(t, &endp, 10);
    }
    out->start = (uint64_t)start;
    out->end = (uint64_t)end;
    out->total = (uint64_t)total;
    return true;
}

#endif  // LANPLAYER_ISO_HTTP_RANGE_H
