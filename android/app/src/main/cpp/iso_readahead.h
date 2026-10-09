// iso_readahead.h —— ISO 远端读取的顺序预读窗口（纯逻辑：无 IO、无线程）
//
// 为什么需要它：本地服务每次只向远端要 32KB（`serve_connection` 的缓冲大小），
// 于是解码器需要 44Mbps 时，远端请求频率约 172 次/秒 —— 吞吐被钉死在
// 「32KB ÷ 每请求延迟」上。真机实测：5GHz 链路的单流吞吐有 193MB/s，但
// Emby 每次 Range 响应的处理时间叠加后，32KB/次仍然喂不饱原盘，表现为
// 「不那么频繁但仍在卡」。
//
// 这个类把远端抓取的**决策**从 socket 代码里剥出来（抓多大、抓几次、预取哪一块、
// 满了淘汰谁、失败怎么重试），既能被宿主单测覆盖，也避免把这类细节埋在
// 一坨 recv/send 里（写错了在真机上只表现为"偶尔卡一下"，极难定位）。
//
// 线程模型：本类**不含锁**。调用方（iso_native.cpp）在外层持有互斥量，
// 并把"抓取中"的等待交给条件变量 —— 见 test 8：抓取中的块不应被重复报缺。

#ifndef LANPLAYER_ISO_READAHEAD_H
#define LANPLAYER_ISO_READAHEAD_H

#include <cstddef>
#include <cstdint>

class ReadAheadWindow {
public:
    /// @param blockBytes 单次远端抓取的块大小（对齐到该边界）
    /// @param slots      窗口槽位数（常驻块上限）
    /// @param lookaheadBlocks 预取领先块数（相对当前已服务块）
    ReadAheadWindow(uint64_t blockBytes, int slots, int lookaheadBlocks)
        : block_bytes_(blockBytes),
          slots_(slots),
          lookahead_(lookaheadBlocks),
          clock_(0) {
        for (int i = 0; i < kMaxSlots; i++) {
            slots_arr_[i].index = 0;
            slots_arr_[i].state = kEmpty;
            slots_arr_[i].last_use = 0;
        }
    }

    /// 清空窗口（重新打开 ISO / 释放缓冲前必须调用，否则旧块号仍被当作常驻）
    void reset() {
        for (int i = 0; i < kMaxSlots; i++) {
            slots_arr_[i].index = 0;
            slots_arr_[i].state = kEmpty;
            slots_arr_[i].last_use = 0;
        }
        clock_ = 0;
    }

    uint64_t blockBytes() const { return block_bytes_; }
    uint64_t blockOf(uint64_t off) const { return off / block_bytes_; }
    int slots() const { return slots_; }

    /// [off, off+len) 需要抓取哪些块（跳过已常驻与抓取中的），按序写入 out。
    /// @return 写入的块数（0 = 全部命中，可直接从本地窗口取数据）
    int missingBlocks(uint64_t off, size_t len, uint64_t *out, int cap) const {
        if (block_bytes_ == 0 || len == 0) return 0;
        uint64_t first = blockOf(off);
        uint64_t last = blockOf(off + len - 1);
        int n = 0;
        for (uint64_t b = first; b <= last && n < cap; b++) {
            if (!isResident(b) && !isFetching(b)) out[n++] = b;
        }
        return n;
    }

    bool isResident(uint64_t block) const { return find(block) >= 0; }

    /// 常驻/抓取中的块所在槽位下标（调用方据此取块数据缓冲）；-1 = 不在窗口内
    int slotOf(uint64_t block) const { return find(block); }

    bool isFetching(uint64_t block) const {
        int i = find(block);
        return i >= 0 && slots_arr_[i].state == kFetching;
    }

    int residentCount() const {
        int n = 0;
        for (int i = 0; i < slots_; i++) {
            if (slots_arr_[i].state == kResident) n++;
        }
        return n;
    }

    /// 为 block 占一个槽并标记「抓取中」：优先空槽，否则淘汰最久未用且不在抓取中的槽。
    /// @return 槽下标；-1 = 无可用槽（全在抓取中，调用方应等待后重试）
    int acquireSlot(uint64_t block) {
        int existing = find(block);
        if (existing >= 0) {
            if (slots_arr_[existing].state == kFetching) return existing;
            slots_arr_[existing].state = kFetching;  // 重新抓取（上一次失败过）
            return existing;
        }
        int victim = -1;
        for (int i = 0; i < slots_; i++) {
            if (slots_arr_[i].state == kEmpty) {
                victim = i;
                break;
            }
            if (slots_arr_[i].state == kFetching) continue;
            if (victim < 0 || slots_arr_[i].last_use < slots_arr_[victim].last_use) {
                victim = i;
            }
        }
        if (victim < 0) return -1;
        slots_arr_[victim].index = block;
        slots_arr_[victim].state = kFetching;
        return victim;
    }

    void markResident(uint64_t block) {
        int i = find(block);
        if (i >= 0) {
            slots_arr_[i].state = kResident;
            slots_arr_[i].last_use = ++clock_;
        }
    }

    /// 抓取失败：槽位作废（下次读会重新报缺 → 可重试）
    void markFailed(uint64_t block) {
        int i = find(block);
        if (i >= 0) {
            slots_arr_[i].state = kEmpty;
            slots_arr_[i].index = 0;
        }
    }

    /// 读 [off, off+len) 成功后登记：刷新 LRU，并给出下一个预取目标。
    /// @return true 表示应预取 *target（目标已常驻或正在抓取时返回 false）
    bool onServed(uint64_t off, size_t len, uint64_t *target) {
        uint64_t first = blockOf(off);
        uint64_t last = blockOf(off + (len ? len - 1 : 0));
        for (uint64_t b = first; b <= last; b++) {
            int i = find(b);
            if (i >= 0) slots_arr_[i].last_use = ++clock_;
        }
        uint64_t want = last + (uint64_t)lookahead_;
        if (isResident(want) || isFetching(want)) return false;
        if (target) *target = want;
        return true;
    }

private:
    enum State { kEmpty = 0, kFetching = 1, kResident = 2 };
    static const int kMaxSlots = 16;

    struct Slot {
        uint64_t index;
        int state;
        uint64_t last_use;
    };

    int find(uint64_t block) const {
        for (int i = 0; i < slots_; i++) {
            if (slots_arr_[i].state != kEmpty && slots_arr_[i].index == block) return i;
        }
        return -1;
    }

    uint64_t block_bytes_;
    int slots_;
    int lookahead_;
    uint64_t clock_;
    Slot slots_arr_[kMaxSlots];
};

#endif  // LANPLAYER_ISO_READAHEAD_H
