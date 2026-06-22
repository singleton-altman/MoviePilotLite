import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ShortcutItem {
  const ShortcutItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class ShortcutPopover extends StatefulWidget {
  const ShortcutPopover({
    super.key,
    required this.target,
    required this.targetSize,
    required this.items,
    required this.onClose,
  });

  final Offset target;
  final Size targetSize;
  final List<ShortcutItem> items;
  final VoidCallback onClose;

  @override
  State<ShortcutPopover> createState() => _ShortcutPopoverState();
}

class _ShortcutPopoverState extends State<ShortcutPopover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss({VoidCallback? after}) async {
    await _controller.reverse();
    widget.onClose();
    after?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const menuWidth = 260.0;

    final top = widget.target.dy + widget.targetSize.height + 8;
    double left = widget.target.dx;
    // 尽量让菜单保持在屏幕内
    final screenWidth = MediaQuery.of(context).size.width;
    if (left + menuWidth > screenWidth - 8) {
      left = screenWidth - menuWidth - 8;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _dismiss(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // 背景轻微变暗，弱化其他内容
              Container(
                color: Colors.black26.withValues(alpha: 0.8 * _opacity.value),
              ),
              Positioned(
                left: left,
                top: top,
                child: Transform.scale(
                  scale: _scale.value,
                  alignment: Alignment.topLeft,
                  child: Opacity(opacity: _opacity.value, child: child),
                ),
              ),
            ],
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: menuWidth,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.items.length; i++) ...[
                  _ShortcutRow(
                    item: widget.items[i],
                    primary: primary,
                    onTap: () => _dismiss(after: widget.items[i].onTap),
                  ),
                  if (i != widget.items.length - 1)
                    const Divider(height: 1, thickness: 0.5),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.item,
    required this.primary,
    required this.onTap,
  });

  final ShortcutItem item;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(item.icon, color: primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
