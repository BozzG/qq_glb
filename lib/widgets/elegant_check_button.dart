import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// 精致打卡按钮（新风格：墨色系，细线描边，微缩放反馈）
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

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
  }

  @override
  void dispose() {
    _controller.dispose();
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
      child: AnimatedBuilder(
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
                color: widget.isChecked ? AppElegant.accent : AppElegant.hair,
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
    );
  }
}
