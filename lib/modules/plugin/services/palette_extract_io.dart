import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

Future<Color> extractPaletteFromCachedFile(
  Object? file,
  Color defaultColor,
) async {
  if (file is! File) return defaultColor;
  final palette = await PaletteGenerator.fromImageProvider(
    FileImage(file),
    maximumColorCount: 6,
    size: const Size(80, 80),
  );
  return palette.dominantColor?.color ?? defaultColor;
}
