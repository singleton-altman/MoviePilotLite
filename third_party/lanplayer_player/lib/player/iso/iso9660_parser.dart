import 'bd_iso_types.dart';

/// ISO9660(含 Joliet)目录树解析器 —— 蓝光 ISO 直连的核心。
///
/// 蓝光原盘 ISO 是 UDF 2.50 卷,但绝大多数制作工具会同时写入
/// ISO9660/Joliet 桥(卷描述符序列里 BEA01 引导记录就是桥的标志,
/// 真盘 0x8000 处已实证)。桥内的目录项记录了 BDMV/STREAM/*.m2ts 的
/// 扇区位置,据此可用 HTTP Range 直接抽取正片 m2ts 的字节区间,
/// 实现客户端原盘直连(无需服务器转码)。
///
/// 纯 UDF 卷(无 ISO9660 桥)v1 不支持 —— parse 返回 null 并带原因。
class Iso9660Parser {
  Iso9660Parser(this._reader);

  static const int _sector = 2048;

  final IsoRangeReader _reader;

  String? _failReason;

  String? get failReason => _failReason;

  Future<List<int>> _read(int start, int end) => _reader(start, end);

  /// 卷描述符里的根目录记录(解析后的目录项)。

  /// 是否使用 Joliet(UCS-2BE 长名)解析目录;否则用 ISO9660 基础名。
  bool _joliet = false;

  /// 解析整个目录树。失败返回 null([failReason] 给出原因)。
  Future<BdIsoTree?> parse() async {
    final root = await _findRoot();
    if (root == null) return null;

    final entries = <String, BdIsoFile>{};
    await _walk(root.lba, root.size, '', entries);

    if (entries.isEmpty) {
      _failReason = '目录树为空';
      return null;
    }
    final bdmv = entries.keys.where((p) => p.startsWith('BDMV/')).length;
    if (bdmv == 0) {
      _failReason = 'ISO 内未找到 BDMV 目录(不是蓝光原盘镜像?)';
      return null;
    }
    return BdIsoTree(entries: entries);
  }

  /// 扫描卷描述符序列:优先 Joliet 补充卷(SVD),回落 ISO9660 主卷(PVD)。
  Future<_DirEntry?> _findRoot() async {
    _DirEntry? isoRoot;
    _DirEntry? jolietRoot;
    var jolietOk = false;

    for (var sector = 16; sector < 32; sector++) {
      final vd = await _read(sector * _sector, (sector + 1) * _sector);
      final type = vd[0];
      final id = String.fromCharCodes(vd.sublist(1, 6)); // 'CD001'
      if (id != 'CD001') continue;
      if (type == 255) break; // 卷描述符终止符
      if (type == 1) {
        isoRoot ??= _parseDirEntry(vd, 156);
      } else if (type == 2) {
        // Joliet 转义序列 %/@ %/C %/E 表示 UCS-2 层级
        final esc = String.fromCharCodes(vd.sublist(88, 91));
        jolietOk = esc == '%/@' || esc == '%/C' || esc == '%/E';
        final r = _parseDirEntry(vd, 156);
        if (jolietOk && r != null) {
          jolietRoot = r;
          _joliet = true;
        }
      }
    }

    if (jolietRoot != null && jolietOk) return jolietRoot;
    if (isoRoot != null) {
      _joliet = false;
      return isoRoot;
    }
    _failReason = '未找到 ISO9660/Joliet 卷(纯 UDF 卷 v1 不支持)';
    return null;
  }

  /// 递归遍历目录(防环:目录最多 8 层,总量上限防呆)。
  Future<void> _walk(int lba, int size, String prefix,
      Map<String, BdIsoFile> out,
      {int depth = 0}) async {
    if (depth > 8 || out.length > 5000) return;
    final data = await _read(lba * _sector, lba * _sector + size);
    var pos = 0;
    while (pos < data.length) {
      final recLen = data[pos];
      if (recLen == 0) {
        // 目录项不跨扇区:剩余部分是填充,跳到下一扇区
        pos = ((pos ~/ _sector) + 1) * _sector;
        if (pos >= data.length) break;
        continue;
      }
      final flags = data[pos + 25];
      final nameLen = data[pos + 32];
      final extent = _readBothEndian32(data, pos + 2);
      final fileSize = _readBothEndian32(data, pos + 10);
      final rawName = data.sublist(pos + 33, pos + 33 + nameLen);
      pos += recLen;

      if (nameLen == 1 && (rawName[0] == 0 || rawName[0] == 1)) {
        continue; // . / .. 自引用项
      }
      final name = _decodeName(rawName);
      if (name.isEmpty) continue;
      final path = prefix.isEmpty ? name : '$prefix/$name';
      final isDir = flags & 2 != 0;

      // 目录也入清单(BDMV/PLAYLIST 等目录本身需要可查)
      out[path] = BdIsoFile(path: path, lba: extent, size: fileSize);

      if (isDir) {
        await _walk(extent, fileSize, path, out, depth: depth + 1);
      } else {
        // 大于 4GB 的文件超出 ISO9660 32 位长度字段(值回绕):
        // 用「下一个条目的 LBA 或卷尾」推出真实大小,保证流式边界正确
        var effective = fileSize;
        if (effective == 0 || effective > 0xF0000000) {
          final nextLba = _nextLbaHint(out);
          effective = nextLba != null
              ? (nextLba - extent) * _sector
              : 0;
        }
        out[path] = BdIsoFile(path: path, lba: extent, size: effective);
      }
    }
  }

  /// 同目录下已记录条目的最大结束 LBA(推算超大文件真实尺寸用)。
  int? _nextLbaHint(Map<String, BdIsoFile> out) {
    int? max;
    for (final e in out.values) {
      final end = e.lba + (e.size + _sector - 1) ~/ _sector;
      if (max == null || end > max) max = end;
    }
    return max;
  }

  /// 解析单个目录记录。context 非 null 时解码为当前卷的名字模式。
  _DirEntry? _parseDirEntry(List<int> vd, int offset) {
    final recLen = vd[offset];
    if (recLen == 0) return null;
    final extent = _readBothEndian32(vd, offset + 2);
    final size = _readBothEndian32(vd, offset + 10);
    return _DirEntry(lba: extent, size: size);
  }

  /// ISO9660 双端序 32 位(小端在前,大端在后)。
  int _readBothEndian32(List<int> b, int off) {
    final le = b[off] | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24);
    return le & 0xFFFFFFFF;
  }

  /// 目录名解码:Joliet = UCS-2BE;基础卷 = ASCII,去掉版本号 ";1"。
  String _decodeName(List<int> raw) {
    if (_joliet) {
      if (raw.length >= 5 &&
          raw[raw.length - 5] == 0 &&
          raw[raw.length - 4] == 0x3B) {
        raw = raw.sublist(0, raw.length - 5); // 去 ";1" (UCS-2BE 的 0x00 0x3B)
      }
      final buf = StringBuffer();
      for (var i = 0; i + 1 < raw.length; i += 2) {
        buf.writeCharCode((raw[i] << 8) | raw[i + 1]);
      }
      return buf.toString();
    }
    var s = String.fromCharCodes(raw);
    final semi = s.indexOf(';');
    if (semi > 0) s = s.substring(0, semi);
    return s.trim();
  }
}

class _DirEntry {
  const _DirEntry({required this.lba, required this.size});
  final int lba;
  final int size;
}
