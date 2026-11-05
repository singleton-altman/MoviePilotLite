import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.size = sizeMedium,
    this.message,
    this.messageStyle,
    this.spacing = 12,
  });

  const AppLoading.small({
    super.key,
    this.message,
    this.messageStyle,
    this.spacing = 8,
  }) : size = sizeSmall;

  const AppLoading.large({
    super.key,
    this.message,
    this.messageStyle,
    this.spacing = 18,
  }) : size = sizeLarge;

  static const String asset = 'assets/lottie/loading.json';
  static const double sizeSmall = 72;
  static const double sizeMedium = 132;
  static const double sizeLarge = 220;

  final double size;
  final String? message;
  final TextStyle? messageStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final indicator = AppLoadingIndicator(size: size);
    if (message == null || message!.isEmpty) {
      return indicator;
    }

    final theme = Theme.of(context);
    final textStyle =
        messageStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        SizedBox(height: spacing),
        Text(message!, style: textStyle, textAlign: TextAlign.center),
      ],
    );
  }
}

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size = AppLoading.sizeMedium});

  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        AppLoading.asset,
        fit: BoxFit.contain,
        animate: !reduceMotion,
        repeat: !reduceMotion,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}

class AppLoadingCenter extends StatelessWidget {
  const AppLoadingCenter({
    super.key,
    this.size = AppLoading.sizeMedium,
    this.message,
    this.messageStyle,
    this.spacing = 12,
  });

  const AppLoadingCenter.small({
    super.key,
    this.message,
    this.messageStyle,
    this.spacing = 8,
  }) : size = AppLoading.sizeSmall;

  const AppLoadingCenter.large({
    super.key,
    this.message,
    this.messageStyle,
    this.spacing = 18,
  }) : size = AppLoading.sizeLarge;

  final double size;
  final String? message;
  final TextStyle? messageStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLoading(
        size: size,
        message: message,
        messageStyle: messageStyle,
        spacing: spacing,
      ),
    );
  }
}
