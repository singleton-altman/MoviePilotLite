import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

Future<Color> extractPaletteFromCachedFile(
  Object? file,
  Color defaultColor,
) async {
  if (file is! File) return defaultColor;
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return defaultColor;
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 80,
    targetHeight: 80,
  );
  final frame = await codec.getNextFrame();
  try {
    final palette = await PaletteGenerator.fromImage(
      frame.image,
      maximumColorCount: 6,
    );
    return palette.dominantColor?.color ?? defaultColor;
  } finally {
    frame.image.dispose();
  }
}
