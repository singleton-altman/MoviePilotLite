import 'dart:math';

/// 尺寸格式化工具类
class SizeFormatter {
  /// 格式化尺寸
  /// [bytes] 字节数
  /// [decimals] 小数位数，默认0
  static String formatSize(dynamic bytes, [int decimals = 0]) {
    if (bytes == null || bytes == 0) return '0 B';

    // 转换为double类型
    final double bytesDouble;
    if (bytes is int) {
      bytesDouble = bytes.toDouble();
    } else if (bytes is double) {
      bytesDouble = bytes;
    } else {
      try {
        bytesDouble = double.parse(bytes.toString());
      } catch (e) {
        return '0 B';
      }
    }

    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = log(bytesDouble) / log(k);
    final index = i.floor().clamp(0, sizes.length - 1);
    final size = bytesDouble / pow(k, index);

    return '${size.toStringAsFixed(decimals)} ${sizes[index]}';
  }

  static String formatSizeFromMb(dynamic mb, [int decimals = 0]) {
    if (mb == null || mb == 0) return '0 MB';
    return formatSize(mb * 1024 * 1024, decimals);
  }
}
