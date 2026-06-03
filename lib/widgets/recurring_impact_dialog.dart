import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  RecurringImpactDialog · 修改重复规则影响范围确认弹窗
///  PRD: docs/prd/recurring-rule-edit.md（AC-21 / AC-22 / AC-23）
///  Design: docs/design/recurring-rule-edit.md §5
/// ─────────────────────────────────────────────────────────────
class RecurringImpactDialog extends StatelessWidget {
  final int deleteCount;
  final int keepCount;
  final int createCount;
  final String sampleLine;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const RecurringImpactDialog({
    super.key,
    required this.deleteCount,
    required this.keepCount,
    required this.createCount,
    required this.sampleLine,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认修改重复规则'),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ImpactRow(
            icon: Icons.delete_sweep_outlined,
            iconColor: AppElegant.rose,
            text: '将删除 $deleteCount 条未来未打卡实例',
          ),
          const SizedBox(height: 14),
          _ImpactRow(
            icon: Icons.lock_outline,
            iconColor: AppElegant.sage,
            text: '保留 $keepCount 条已打卡或今天及之前实例',
          ),
          const SizedBox(height: 14),
          _ImpactRow(
            icon: Icons.add_circle_outline,
            iconColor: AppElegant.accent,
            text: '按新规则重建 $createCount 条实例',
          ),
          const SizedBox(height: 14),
          if (sampleLine.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(sampleLine, style: AppText.meta),
            ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppElegant.accent),
          onPressed: onConfirm,
          child: const Text('确认修改'),
        ),
      ],
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _ImpactRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppElegant.ink,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// 根据 toCreate 列表生成"示例日期：…"行文案。
/// 矩阵详见 design §5.4：
/// - K = 0：返回空串（不应到达）。
/// - K ∈ {1,2,3}：全列，不带"…等共 N 条"。
/// - K > 3：取首 / `(K/2).floor()` / 末，附"…等共 K 条"。
String buildSampleLine(List<DateTime> toCreate) {
  String fmt(DateTime d) {
    const w = ['一', '二', '三', '四', '五', '六', '日'];
    return '${d.month}/${d.day} 周${w[d.weekday - 1]}';
  }

  final k = toCreate.length;
  if (k == 0) return '';
  if (k <= 3) {
    return '示例日期：${toCreate.map(fmt).join('、')}';
  }
  final first = toCreate.first;
  final mid = toCreate[(k / 2).floor()];
  final last = toCreate.last;
  return '示例日期：${fmt(first)}、${fmt(mid)}、${fmt(last)} …等共 $k 条';
}
