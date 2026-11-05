import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_item_card.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class MusicTheme extends StatelessWidget {
  const MusicTheme({super.key, required this.child});

  final Widget child;

  static Color accentOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFF5266)
      : const Color(0xFFD92D46);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final accent = accentOf(context);
    final background = dark ? const Color(0xFF000000) : Colors.white;
    final foreground = dark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F);
    final secondary = dark ? const Color(0xFFABABB0) : const Color(0xFF68686D);
    final surface = dark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final scheme = base.colorScheme.copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: background,
      onSurface: foreground,
      onSurfaceVariant: secondary,
      surfaceContainerLow: surface,
      surfaceContainerHighest: surface,
      outlineVariant: dark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
    );
    return Theme(
      data: base.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        textTheme: base.textTheme.apply(
          bodyColor: foreground,
          displayColor: foreground,
        ),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: background,
          foregroundColor: accent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: foreground,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: accent,
          selectionColor: accent.withValues(alpha: 0.2),
        ),
        dividerColor: scheme.outlineVariant,
      ),
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: base.brightness,
          primaryColor: accent,
        ),
        child: child,
      ),
    );
  }
}

class MusicArtwork extends StatelessWidget {
  const MusicArtwork({
    super.key,
    this.imageUrl,
    this.isArtist = false,
    this.size,
    this.elevated = false,
  });

  final String? imageUrl;
  final bool isArtist;
  final double? size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(isArtist ? 1000 : 8);
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF343038), Color(0xFF211D25)]
              : const [Color(0xFFF4EDF0), Color(0xFFE5E0E9)],
        ),
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) => Icon(
            isArtist ? CupertinoIcons.person_fill : CupertinoIcons.music_note_2,
            size: (constraints.maxWidth * 0.3).clamp(22, 76),
            color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
    final url = imageUrl?.trim() ?? '';
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.3 : 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: AspectRatio(
            aspectRatio: 1,
            child: url.isEmpty
                ? placeholder
                : CachedImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: placeholder,
                    errorWidget: placeholder,
                  ),
          ),
        ),
      ),
    );
  }
}

class MusicAlbumGrid extends StatelessWidget {
  const MusicAlbumGrid({super.key, required this.items, this.onOpen});

  final List<MusicExploreItem> items;
  final ValueChanged<MusicExploreItem>? onOpen;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final scaler = MediaQuery.textScalerOf(context);
        final minWidth = scaler.scale(15) > 24 ? 210.0 : 150.0;
        final columns = math.max(
          1,
          ((width - 40 + 18) / (minWidth + 18)).floor(),
        );
        final cardWidth = (width - 40 - (columns - 1) * 18) / columns;
        // Grid cells reserve space for two title lines and a scaled subtitle.
        final extent =
            cardWidth +
            18 +
            scaler.scale(15) * 2 * 1.3 +
            scaler.scale(13) * 1.35;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 18,
              mainAxisSpacing: 20,
              mainAxisExtent: extent,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => MusicItemCard(
                item: items[index],
                cardWidth: cardWidth,
                onTap: onOpen == null ? null : () => onOpen!(items[index]),
              ),
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }
}

class MusicSectionHeading extends StatelessWidget {
  const MusicSectionHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (subtitle?.isNotEmpty == true) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MusicStateView extends StatelessWidget {
  const MusicStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = CupertinoIcons.music_note_2,
    this.onRetry,
  });

  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 46, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              CupertinoButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ],
        ),
      ),
    );
  }
}

class MusicSearchField extends StatelessWidget {
  const MusicSearchField({
    super.key,
    required this.onSubmitted,
    this.initialValue,
  });

  final ValueChanged<String> onSubmitted;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      initialValue: initialValue,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      style: const TextStyle(fontSize: 17),
      onFieldSubmitted: (value) {
        final term = value.trim();
        if (term.isEmpty) return;
        FocusScope.of(context).unfocus();
        onSubmitted(term);
      },
      decoration: InputDecoration(
        hintText: '艺人、专辑或歌曲',
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 17),
        prefixIcon: Icon(
          CupertinoIcons.search,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
    );
  }
}
