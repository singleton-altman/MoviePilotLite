import 'dart:collection';

/// 按「字节预算」做 LRU 逐出的常驻对象池。
///
/// 为弹幕位图而生：弹幕位图是原生内存（ui.Image），每条激活都新生成一张
/// 的话，密集段就是每秒数次原生分配/释放 → NativeAlloc GC 风暴（TV 真机
/// gfxinfo 2026-09-06 实证：高峰 2 次/秒，掉帧 44.94%）。弹幕同文本极多
/// （"666""哈哈哈"），按「文本+样式」key 常驻复用后命中零分配。
///
/// 泛型 + 注入 sizeOf/onEvict：真实位图传 `sizeOf: (img)=>img.width*img.height*4`、
/// `onEvict: img.dispose`；测试可注入任意值（见 test/danmaku_perf_test.dart）。
class LruBytePool<T> {
  LruBytePool({
    required this.maxBytes,
    required int Function(T) sizeOf,
    required void Function(T) onEvict,
  })  : _sizeOf = sizeOf,
        _onEvict = onEvict;

  /// 池总字节上限。超出时从最久未使用的条目开始逐出。
  final int maxBytes;
  final int Function(T) _sizeOf;
  final void Function(T) _onEvict;

  // LinkedHashMap 按插入/访问序排列：get 命中后 move 到末尾，首项即最旧。
  final LinkedHashMap<String, T> _entries = LinkedHashMap();

  int _bytes = 0;
  int get bytes => _bytes;
  int get length => _entries.length;

  /// 取缓存并刷新新鲜度；未命中返回 null。
  T? get(String key) {
    final v = _entries.remove(key);
    if (v == null) return null;
    _entries[key] = v; // move-to-tail：刚刚被用过，是最新鲜的
    return v;
  }

  /// 放入并按预算逐出最旧条目。单条超过总预算的：不入池，直接回调释放。
  void put(String key, T value) {
    _entries.remove(key); // 同 key 覆盖：先按旧值记账
    final size = _sizeOf(value);
    if (size > maxBytes) {
      _onEvict(value);
      return;
    }
    while (_bytes + size > maxBytes && _entries.isNotEmpty) {
      final oldestKey = _entries.keys.first;
      final oldest = _entries.remove(oldestKey)!;
      _bytes -= _sizeOf(oldest);
      _onEvict(oldest);
    }
    _entries[key] = value;
    _bytes += size;
  }

  /// 清空并逐个回调释放（控制器 dispose 时调用）。
  void disposeAll() {
    for (final v in _entries.values) {
      _onEvict(v);
    }
    _entries.clear();
    _bytes = 0;
  }
}
