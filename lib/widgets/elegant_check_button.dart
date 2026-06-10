import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// 精致打卡按钮（墨色系，细线描边，微缩放反馈 + 打卡成功爆发动效）
///
/// 交互反馈分两段：
/// 1. 点击瞬间：触感 + 220ms 缩放回弹（即时操作确认）。
/// 2. 打卡成功（未打卡→已打卡）：扩散光环 + 放射粒子 + 中等触感，
///    与「记录成长」的仪式感定位匹配，避免核心操作零反馈。
class ElegantCheckInButton extends StatefulWidget {
  final bool isChecked;
  final VoidCallback onTap;
  final Color scheduleColor;

  const ElegantCheckInButton({
    super.key,
    required this.isChecked,
    required this.onTap,
    required this.scheduleColor,
  });

  @override
  State<ElegantCheckInButton> createState() => _ElegantCheckInButtonState();
}

class _ElegantCheckInButtonState extends State<ElegantCheckInButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  /// 打卡成功爆发动效控制器（扩散环 + 放射粒子）
  late AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 60),
    ]).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _burst = AnimationController(
      duration: const Duration(milliseconds: 560),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant ElegantCheckInButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅在「未打卡 → 已打卡」迁移时播放爆发动效
    if (!oldWidget.isChecked && widget.isChecked) {
      HapticFeedback.mediumImpact();
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    _controller.forward(from: 0).then((_) {
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 爆发动效层（溢出 36 边界，置于按钮下方）
            AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                if (_burst.isDismissed) return const SizedBox.shrink();
                return IgnorePointer(
                  child: CustomPaint(
                    size: const Size(64, 64),
                    painter: _BurstPainter(
                      progress: _burst.value,
                      color: AppElegant.accent,
                    ),
                  ),
                );
              },
            ),
            // 按钮本体
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.scale(
                scale: _scale.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isChecked ? AppElegant.accent : AppElegant.card,
                    border: Border.all(
                      color: widget.isChecked
                          ? AppElegant.accent
                          : AppElegant.hair,
                      width: widget.isChecked ? 1 : 0.8,
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.isChecked
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        key: ValueKey(widget.isChecked),
                        size: widget.isChecked ? 18 : 16,
                        color: widget.isChecked
                            ? Colors.white
                            : AppElegant.inkWhisper,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 打卡成功爆发：一圈扩散淡出的光环 + 6 颗放射粒子。
class _BurstPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  _BurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = Curves.easeOut.transform(progress);

    // 扩散光环
    final ringRadius = lerpDouble(15, 28, t)!;
    final ringOpacity = (1 - progress).clamp(0.0, 1.0) * 0.55;
    if (ringOpacity > 0) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lerpDouble(3.0, 0.5, t)!
        ..color = color.withValues(alpha: ringOpacity);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // 放射粒子
    final dist = lerpDouble(12, 26, t)!;
    final dotOpacity = (1 - progress).clamp(0.0, 1.0);
    if (dotOpacity > 0) {
      final dotPaint = Paint()..color = color.withValues(alpha: dotOpacity);
      const count = 6;
      final dotRadius = lerpDouble(2.2, 0.4, t)!;
      for (var i = 0; i < count; i++) {
        final angle = (i / count) * 2 * math.pi - math.pi / 2;
        final p = center +
            Offset(math.cos(angle), math.sin(angle)) * dist;
        canvas.drawCircle(p, dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
