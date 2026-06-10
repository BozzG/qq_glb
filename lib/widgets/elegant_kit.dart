import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        ?trailing,
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
          ?trailing,
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

/// 确认弹窗的一个操作项
class ElegantDialogAction<T> {
  /// 按钮文案
  final String label;

  /// 点击后回传的值（经 Navigator.pop 返回）
  final T? value;

  /// 是否为取消项（渲染为 TextButton，不填充）
  final bool isCancel;

  /// 填充按钮背景色（仅非取消项生效）；为空时取 AppElegant.accent
  final Color? color;

  const ElegantDialogAction({
    required this.label,
    this.value,
    this.isCancel = false,
    this.color,
  });
}

/// 统一确认弹窗：精致风格的二次确认对话框。
///
/// · 复用全局 dialogTheme（圆角 20 / card 底 / ink 标题）。
/// · 支持取消 + 单确认（删除/重置），也支持多分支（如重复日程的 仅此项/全部）。
/// · 推荐通过静态方法 [show] / [confirmDelete] 调用。
class ElegantConfirmDialog<T> extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final List<ElegantDialogAction<T>> actions;

  const ElegantConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.icon,
  });

  /// 通用入口：返回所点操作项的 value（取消通常为 null/false）。
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String message,
    required List<ElegantDialogAction<T>> actions,
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => ElegantConfirmDialog<T>(
        title: title,
        message: message,
        actions: actions,
        icon: icon,
      ),
    );
  }

  /// 删除/破坏性操作快捷入口：取消 + 红色确认，返回 true 表示确认。
  static Future<bool> confirmDelete(
    BuildContext context, {
    String title = '删除确认',
    required String message,
    String confirmLabel = '删除',
    String cancelLabel = '取消',
    IconData? icon = Icons.delete_outline_rounded,
  }) async {
    final result = await show<bool>(
      context,
      title: title,
      message: message,
      icon: icon,
      actions: [
        ElegantDialogAction(label: cancelLabel, value: false, isCancel: true),
        ElegantDialogAction(
          label: confirmLabel,
          value: true,
          color: AppElegant.rose,
        ),
      ],
    );
    return result == true;
  }

  Widget _buildAction(BuildContext context, ElegantDialogAction<T> a) {
    if (a.isCancel) {
      return TextButton(
        onPressed: () => Navigator.pop(context, a.value),
        child: Text(a.label),
      );
    }
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: a.color ?? AppElegant.accent,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context, a.value);
      },
      child: Text(a.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppElegant.accent),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: actions.map((a) => _buildAction(context, a)).toList(),
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

/// ─────────────────────────────────────────────────────────────
///  统一加载指示器
///  · 替代各页面散落的 CircularProgressIndicator / CupertinoActivityIndicator
///  · 默认走品牌强调色，可选文案
/// ─────────────────────────────────────────────────────────────
class ElegantLoading extends StatelessWidget {
  final double size;
  final String? label;
  final Color? color;

  const ElegantLoading({super.key, this.size = 28, this.label, this.color});

  /// 居中铺满（常用于页面级 loading 占位）
  static Widget center({String? label}) =>
      Center(child: ElegantLoading(label: label));

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppElegant.accent;
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(c),
      ),
    );
    if (label == null) return indicator;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: 12),
        Text(
          label!,
          style: const TextStyle(fontSize: 13, color: AppElegant.inkSoft),
        ),
      ],
    );
  }
}

/// 底部弹窗通用头部（取消 / 标题 / 完成）—— 供选择器复用
class _ElegantPickerHeader extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _ElegantPickerHeader({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: onCancel,
            child: const Text('取消',
                style: TextStyle(color: AppElegant.inkSoft, fontSize: 15)),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppElegant.ink,
              letterSpacing: 1,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: onConfirm,
            child: const Text('完成',
                style: TextStyle(
                    color: AppElegant.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// 通用底部 Cupertino 选择器容器
Future<DateTime?> _showElegantPickerSheet({
  required BuildContext context,
  required String title,
  required Widget Function(ValueChanged<DateTime> onChanged) buildPicker,
  required DateTime initial,
  double height = 320,
}) async {
  DateTime temp = initial;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppElegant.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const ElegantSheetHandle(),
            _ElegantPickerHeader(
              title: title,
              onCancel: () => Navigator.pop(ctx),
              onConfirm: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx, temp);
              },
            ),
            Expanded(child: buildPicker((v) => temp = v)),
          ],
        ),
      ),
    ),
  );
}

/// ─────────────────────────────────────────────────────────────
///  统一日期选择器（底部弹窗）
///  用法：final d = await ElegantDatePicker.show(context, initial: x);
/// ─────────────────────────────────────────────────────────────
class ElegantDatePicker {
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initial,
    DateTime? minimumDate,
    DateTime? maximumDate,
    String title = '日期',
  }) {
    return _showElegantPickerSheet(
      context: context,
      title: title,
      initial: initial,
      buildPicker: (onChanged) => CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: initial,
        minimumDate: minimumDate ?? DateTime(2020),
        maximumDate: maximumDate ?? DateTime(2035),
        onDateTimeChanged: onChanged,
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
///  统一时间选择器（底部弹窗，24h）
///  用法：final t = await ElegantTimePicker.show(context, initial: x);
/// ─────────────────────────────────────────────────────────────
class ElegantTimePicker {
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initial,
    int minuteInterval = 5,
    String title = '时间',
  }) {
    return _showElegantPickerSheet(
      context: context,
      title: title,
      initial: initial,
      height: 280,
      buildPicker: (onChanged) => CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: initial,
        use24hFormat: true,
        minuteInterval: minuteInterval,
        onDateTimeChanged: onChanged,
      ),
    );
  }
}
