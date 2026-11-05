import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

final agentFloatingEntryRouteHidden = ValueNotifier<bool>(false);

class AgentFloatingRouteObserver extends NavigatorObserver {
  void _sync(Route<dynamic>? route) {
    agentFloatingEntryRouteHidden.value = route?.settings.name == '/agent';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sync(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sync(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _sync(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sync(newRoute);
  }
}

class AgentFloatingEntry extends StatefulWidget {
  const AgentFloatingEntry({super.key});

  @override
  State<AgentFloatingEntry> createState() => _AgentFloatingEntryState();
}

class _AgentFloatingEntryState extends State<AgentFloatingEntry>
    with SingleTickerProviderStateMixin {
  static const Size _entrySize = Size(50, 50);
  static const double _edgePadding = 14;

  Offset? _position;
  Animation<Offset>? _snapAnimation;
  late final AnimationController _snapController;
  bool _dragged = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _snapController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 260),
          )
          ..addListener(() {
            final animation = _snapAnimation;
            if (animation == null || !mounted) return;
            setState(() => _position = animation.value);
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _snapAnimation = null;
            }
          });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: agentFloatingEntryRouteHidden,
      builder: (context, hiddenByRoute, _) {
        return Obx(() {
          final appService = Get.find<AppService>();
          if (hiddenByRoute || !appService.canShowAiAgentEntry) {
            return const SizedBox.shrink();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (!constraints.hasBoundedWidth ||
                  !constraints.hasBoundedHeight) {
                return const SizedBox.shrink();
              }

              final safePadding = MediaQuery.paddingOf(context);
              final minY = safePadding.top + kToolbarHeight + _edgePadding;
              final maxY =
                  constraints.maxHeight -
                  _entrySize.height -
                  safePadding.bottom -
                  _edgePadding;
              final bounds = _DragBounds(
                minX: _edgePadding,
                maxX: (constraints.maxWidth - _entrySize.width - _edgePadding)
                    .clamp(_edgePadding, double.infinity),
                minY: minY,
                maxY: maxY < minY ? minY : maxY,
              );
              final current = _constrainPosition(
                _position ?? Offset(bounds.maxX, constraints.maxHeight * 0.62),
                bounds,
              );
              if (_position != current) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _position = current);
                  }
                });
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: current.dx,
                    top: current.dy,
                    width: _entrySize.width,
                    height: _entrySize.height,
                    child: _AgentFloatingButton(
                      isDragging: _isDragging,
                      onTap: _openAgent,
                      onDragStart: () {
                        _snapController.stop();
                        setState(() {
                          _dragged = false;
                          _isDragging = true;
                        });
                      },
                      onDragUpdate: (delta) {
                        _dragged = true;
                        setState(() {
                          final latest = _position ?? current;
                          _position = _constrainPosition(
                            latest + delta,
                            bounds,
                          );
                        });
                      },
                      onDragEnd: () {
                        final latest = _position ?? current;
                        final wasDragged = _dragged;
                        final centerX =
                            bounds.minX + (bounds.maxX - bounds.minX) / 2;
                        final target = _constrainPosition(
                          Offset(
                            latest.dx < centerX ? bounds.minX : bounds.maxX,
                            latest.dy,
                          ),
                          bounds,
                        );
                        setState(() => _isDragging = false);
                        _animateTo(target, bounds);
                        if (wasDragged) {
                          Future<void>.delayed(
                            const Duration(milliseconds: 80),
                            () {
                              if (mounted) _dragged = false;
                            },
                          );
                        }
                      },
                      shouldIgnoreTap: () => _dragged,
                    ),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }

  void _animateTo(Offset target, _DragBounds bounds) {
    final begin = _constrainPosition(_position ?? target, bounds);
    final end = _constrainPosition(target, bounds);
    if ((begin - end).distance < 0.5) {
      setState(() => _position = end);
      return;
    }

    _snapAnimation = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
  }

  Offset _constrainPosition(Offset value, _DragBounds bounds) {
    return Offset(
      value.dx.clamp(bounds.minX, bounds.maxX).toDouble(),
      value.dy.clamp(bounds.minY, bounds.maxY).toDouble(),
    );
  }

  void _openAgent() {
    if (_dragged) return;
    if (Get.currentRoute == '/agent') return;
    Get.toNamed('/agent');
  }
}

class _AgentFloatingButton extends StatefulWidget {
  const _AgentFloatingButton({
    required this.isDragging,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.shouldIgnoreTap,
  });

  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final bool Function() shouldIgnoreTap;

  @override
  State<_AgentFloatingButton> createState() => _AgentFloatingButtonState();
}

class _AgentFloatingButtonState extends State<_AgentFloatingButton>
    with SingleTickerProviderStateMixin {
  static const String _petAsset = 'assets/lottie/Flirting_Dog.json';

  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animate = !reduceMotion && !widget.isDragging;

    return Semantics(
      button: true,
      label: 'AI 对话助手',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!widget.shouldIgnoreTap()) widget.onTap();
        },
        onPanStart: (_) => widget.onDragStart(),
        onPanUpdate: (details) => widget.onDragUpdate(details.delta),
        onPanEnd: (_) => widget.onDragEnd(),
        onPanCancel: widget.onDragEnd,
        child: AnimatedScale(
          scale: widget.isDragging ? 0.94 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              final drift = animate
                  ? math.sin(_ringController.value * math.pi * 2) * 1.2
                  : 0.0;
              return Transform.translate(
                offset: Offset(0, drift),
                child: child,
              );
            },
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (animate)
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(72, 72),
                          painter: _AuroraRingPainter(
                            progress: _ringController.value,
                            primary: colorScheme.primary,
                            tertiary: colorScheme.tertiary,
                          ),
                        );
                      },
                    ),
                  Positioned(
                    bottom: 4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: widget.isDragging ? 28 : 34,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colorScheme.shadow.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.surface.withValues(alpha: 0.88),
                              colorScheme.primaryContainer.withValues(
                                alpha: 0.72,
                              ),
                            ],
                          ),
                          border: Border.all(
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.28,
                            ),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: colorScheme.tertiary.withValues(
                                alpha: 0.16,
                              ),
                              blurRadius: 10,
                              offset: const Offset(-3, -2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Lottie.asset(
                            _petAsset,
                            fit: BoxFit.contain,
                            animate: animate,
                            repeat: animate,
                            errorBuilder: (_, __, ___) => Icon(
                              CupertinoIcons.sparkles,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: _SparkleBadge(
                      colorScheme: colorScheme,
                      pulse: animate,
                      progress: _ringController.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkleBadge extends StatelessWidget {
  const _SparkleBadge({
    required this.colorScheme,
    required this.pulse,
    required this.progress,
  });

  final ColorScheme colorScheme;
  final bool pulse;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = pulse ? 1 + math.sin(progress * math.pi * 4) * 0.08 : 1.0;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [colorScheme.tertiary, colorScheme.primary],
          ),
          border: Border.all(
            color: colorScheme.onPrimary.withValues(alpha: 0.72),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.32),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.sparkles,
          size: 12,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _AuroraRingPainter extends CustomPainter {
  const _AuroraRingPainter({
    required this.progress,
    required this.primary,
    required this.tertiary,
  });

  final double progress;
  final Color primary;
  final Color tertiary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = math.pi * 1.35;
    final start = progress * math.pi * 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [
          primary.withValues(alpha: 0),
          primary.withValues(alpha: 0.72),
          tertiary.withValues(alpha: 0.88),
          primary.withValues(alpha: 0),
        ],
        stops: const [0, 0.35, 0.62, 1],
      ).createShader(rect);

    canvas.drawArc(rect, start, sweep, false, paint);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = primary.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, start + math.pi, sweep * 0.72, false, glow);
  }

  @override
  bool shouldRepaint(covariant _AuroraRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.tertiary != tertiary;
  }
}

class _DragBounds {
  const _DragBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
}
