import 'package:flutter/cupertino.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class MixedImgWidget extends StatelessWidget {
  const MixedImgWidget({
    super.key,
    required this.imageUrls,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final List<String> imageUrls;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox();

    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _getCrossAxisCount(imageUrls.length);

          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final itemWidth = width / crossAxisCount;

          final rowCount = (imageUrls.length / crossAxisCount).ceil();
          final itemHeight = height / rowCount;

          final aspectRatio = itemWidth / itemHeight;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: imageUrls.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio, // ⭐ 关键
            ),
            itemBuilder: (_, index) {
              return CachedImage(imageUrl: imageUrls[index], fit: BoxFit.cover);
            },
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(int length) {
    if (length <= 1) return 1;
    if (length <= 4) return 2;
    return 3;
  }
}
