import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  精致风格通用组件库（elegant_kit）
///  按需 import '../widgets/elegant_kit.dart';
/// ─────────────────────────────────────────────────────────────

/// 统一页面脚手架：米白底 + SafeArea + 可选导航栏
class ElegantScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottom;
  final PreferredSizeWidget? appBar;
  final bool safeAreaBottom;

  const ElegantScaffold({
    super.key,
    required this.body,
    this.bottom,
    this.appBar,
    this.safeAreaBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppElegant.bg,
      appBar: appBar,
      body: SafeArea(bottom: safeAreaBottom, child: body),
      bottomNavigationBar: bottom,
    );
  }
}

/// 精致顶部导航栏（无 AppBar 分隔线）
class ElegantNavBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const ElegantNavBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          leading ??
              (Navigator.canPop(context)
                  ? ElegantCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBack ?? () => Navigator.pop(context),
                    )
                  : const SizedBox(width: 40)),
          Expanded(
            child: Center(child: Text(title, style: AppText.navTitle)),
          ),
          if (actions != null) ...actions! else const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// 圆形图标按钮
class ElegantCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;

  const ElegantCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppElegant.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppElegant.hair, width: 0.5),
        ),
        child: Icon(icon, size: 16, color: iconColor ?? AppElegant.ink),
      ),
    );
  }
}

/// 卡片容器：白色+细边+微阴影
class ElegantCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;

  const ElegantCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppElegant.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppElegant.hair, width: 0.5),
        boxShadow: AppElegant.softShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// 卡片小标题（带图标）
class ElegantCardHeader extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Widget? trailing;

  const ElegantCardHeader({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppElegant.inkSoft),
          const SizedBox(width: 8),
        ],
        Text(label, style: AppText.caption),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 发丝分隔线
class ElegantDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  const ElegantDivider({super.key, this.indent = 0, this.endIndent = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      color: AppElegant.hair,
    );
  }
}

/// 行列表项（label 左 value 右 → 箭头）
class ElegantRowTile extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? leading;

  const ElegantRowTile({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, size: 18, color: AppElegant.inkSoft),
            const SizedBox(width: 12),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppElegant.inkSoft),
          ),
          const Spacer(),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppElegant.ink,
              ),
            ),
          if (trailing != null) trailing!,
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppElegant.inkWhisper,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return tile;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      borderRadius: BorderRadius.circular(10),
      child: tile,
    );
  }
}

/// 胶囊芯片：细描边，单选高亮
class ElegantChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;

  const ElegantChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final acc = accentColor ?? AppElegant.accent;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? acc.withValues(alpha: 0.08) : AppElegant.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? acc.withValues(alpha: 0.5) : AppElegant.hair,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? acc : AppElegant.inkSoft),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? acc : AppElegant.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分段按钮（深黑填充选中态）
class ElegantSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ElegantSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppElegant.accent : AppElegant.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppElegant.accent : AppElegant.hair,
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppElegant.ink,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 主行动按钮（大号黑色）
class ElegantPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const ElegantPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppElegant.accent,
          disabledBackgroundColor: AppElegant.hair,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppElegant.inkFaint,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部浮动行动栏（带渐隐遮罩）
class ElegantFloatingBar extends StatelessWidget {
  final Widget child;
  const ElegantFloatingBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppElegant.bg.withValues(alpha: 0),
              AppElegant.bg.withValues(alpha: 0.95),
              AppElegant.bg,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 空状态
class ElegantEmpty extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final Widget? action;

  const ElegantEmpty({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppElegant.bgAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppElegant.inkFaint),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppElegant.inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppElegant.inkFaint,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// 小统计方格（数字 + 标签）
class ElegantStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? accent;

  const ElegantStatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppElegant.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppElegant.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppElegant.hair, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: c.withValues(alpha: 0.7)),
          if (icon != null) const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: c,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.meta),
        ],
      ),
    );
  }
}

/// 精致输入容器（用于自定义表单行）
class ElegantInputBox extends StatelessWidget {
  final Widget child;
  const ElegantInputBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppElegant.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppElegant.hair, width: 0.5),
      ),
      child: child,
    );
  }
}

/// 显示一个底部拖拽指示条
class ElegantSheetHandle extends StatelessWidget {
  const ElegantSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppElegant.hair,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// 标签徽章（小圆角灰底）
class ElegantBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;

  const ElegantBadge({super.key, required this.text, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppElegant.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: c,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
