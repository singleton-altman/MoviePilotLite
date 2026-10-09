/// BDMV ISO 的目录树解析结果。
class BdIsoTree {
  BdIsoTree({required this.entries});

  /// ISO 内全部文件的扁平清单:路径(全大写,/ 分隔)→ (LBA, 字节数)。
  final Map<String, BdIsoFile> entries;

  /// BDMV/STREAM 下最大的 m2ts(主影片候选,v1 直连目标)。
  BdIsoFile? get largestM2ts {
    BdIsoFile? best;
    for (final e in entries.values) {
      if (!e.path.startsWith('BDMV/STREAM/') ||
          !e.path.toUpperCase().endsWith('.M2TS')) {
        continue;
      }
      if (best == null || e.size > best.size) best = e;
    }
    return best;
  }

  BdIsoFile? find(String path) => entries[path.toUpperCase()];
}

class BdIsoFile {
  const BdIsoFile({required this.path, required this.lba, required this.size});

  /// 起始逻辑扇区号(每扇区 2048 字节)。字节偏移 = lba * 2048。
  final int lba;
  final int size;
  final String path;
}

/// 解析 ISO9660/Joliet 目录树所需的最小读取接口。
///
/// 生产实现 = 对远端 URL 发 Range 请求;测试实现 = 内存字节缓冲。
typedef IsoRangeReader = Future<List<int>> Function(int start, int end);
