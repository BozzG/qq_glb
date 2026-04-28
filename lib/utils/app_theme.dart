import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
///  颜色系统
///  · 旧色板（AppColors.primary 等）仍然保留，以便向后兼容
///  · 新增 AppElegant 优雅色板：米白 + 墨黑 + 发丝线 + 单色强调
/// ─────────────────────────────────────────────────────────────
class AppColors {
  // 主题色 - 兼容保留
  static const Color primary = Color(0xFFE091A5); // 柔和玫瑰粉
  static const Color primaryLight = Color(0xFFFADDE3); // 浅樱花粉
  static const Color primaryDark = Color(0xFFD4738C); // 深玫瑰
  static const Color secondary = Color(0xFFFFB74D); // 暖黄色
  static const Color secondaryLight = Color(0xFFFFF8E1); // 浅黄色
  static const Color accent = Color(0xFF81C784); // 草绿色

  // 打卡完成渐变
  static const Color checkInGradientStart = Color(0xFFF8BBD9);
  static const Color checkInGradientEnd = Color(0xFFA5D6A7);

  // 背景色
  static const Color background = Color(0xFFFAFAF7); // 优雅米白
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // 文字颜色
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textHint = Color(0xFFBDBDBD);

  // 功能色
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF42A5F5);

  // 日程类型颜色（保留）
  static const Color scheduleNursery = Color(0xFFF06292);
  static const Color scheduleSports = Color(0xFF64B5F6);
  static const Color scheduleLanguage = Color(0xFFBA68C8);
  static const Color scheduleMedical = Color(0xFFEF5350);
  static const Color scheduleSchool = Color(0xFF66BB6A);
  static const Color scheduleGeneral = Color(0xFF90A4AE);

  static final List<Color> cartoonPalette = [
    Color(0xFFFF6B9D),
    Color(0xFFFFA07A),
    Color(0xFF98D8C8),
    Color(0xFFBB8FCE),
    Color(0xFFF7DC6F),
    Color(0xFF85C1E9),
  ];
}

/// 精致 · 优雅 · 简洁高端设计色板（玫瑰粉主题）
class AppElegant {
  AppElegant._();

  // 背景/容器 - 微带暖粉调的米白
  static const Color bg = Color(0xFFFBF8F7); // 带微粉暖调的米白主背景
  static const Color bgAlt = Color(0xFFF6EEEF); // 淡粉辅助底
  static const Color card = Color(0xFFFFFFFF);

  // 墨色层级（保留，保证文字可读性）
  static const Color ink = Color(0xFF2B1E22); // 主文字 - 带一丝酒红的深墨
  static const Color inkSoft = Color(0xFF7A6268); // 次级 - 暖灰
  static const Color inkFaint = Color(0xFFA59195); // 三级 - 淡雾灰
  static const Color inkWhisper = Color(0xFFCFBEC2); // 提示/占位

  // 线条 - 微粉色调
  static const Color hair = Color(0xFFEDE6E7); // 发丝分隔线 · 带粉调
  static const Color hairSoft = Color(0xFFF4EEEF); // 更淡分隔

  // 强调色 - 玫瑰粉主色系（高级酒玫瑰，不甜腻）
  static const Color accent = Color(0xFFC9526E); // 主行动色 · Wine Rose
  static const Color accentDark = Color(0xFFA73D56); // 深玫瑰 · 按压态/强调
  static const Color accentLight = Color(0xFFEFC9D3); // 浅粉 · 底色装饰
  static const Color accentWhisper = Color(0xFFFAEDF0); // 极淡粉 · 选中背景
  static const Color onAccent = Colors.white;

  // 微弱色系（给图标/标签用的极低饱和度色）
  static const Color rose = Color(0xFFC9526E); // 与主色一致
  static const Color sage = Color(0xFF7A9278); // 鼠尾草绿
  static const Color sand = Color(0xFFC8A97E); // 沙金
  static const Color slate = Color(0xFF6B7A8F); // 石板蓝
  static const Color plum = Color(0xFF8D6B94); // 梅紫

  // 阴影
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];
}

/// 文字样式
class AppText {
  AppText._();

  // 全大写小标签（如 "TIME" "DETAIL"）
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppElegant.inkSoft,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 13,
    color: AppElegant.inkSoft,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
  );

  static const TextStyle navTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppElegant.ink,
    letterSpacing: 0.3,
  );

  static const TextStyle heroTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppElegant.ink,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle heroHint = TextStyle(
    fontSize: 12,
    color: AppElegant.inkSoft,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
  );

  static const TextStyle bigNumber = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w300,
    color: AppElegant.ink,
    letterSpacing: -1,
    height: 1,
  );

  static const TextStyle itemTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppElegant.ink,
  );

  static const TextStyle itemBody = TextStyle(
    fontSize: 14,
    color: AppElegant.ink,
    height: 1.5,
  );

  static const TextStyle meta = TextStyle(
    fontSize: 12,
    color: AppElegant.inkSoft,
    height: 1.4,
  );
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppElegant.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppElegant.accent,
      primary: AppElegant.accent,
      secondary: AppElegant.accentDark,
      surface: AppElegant.card,
      brightness: Brightness.light,
    ),
    // 使用系统默认字体（SF Pro / PingFang / Roboto），
    // 去除手写风 MaShanZheng 以契合精致优雅风格
    appBarTheme: const AppBarTheme(
      backgroundColor: AppElegant.bg,
      foregroundColor: AppElegant.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppText.navTitle,
      iconTheme: IconThemeData(color: AppElegant.ink, size: 22),
    ),
    cardTheme: CardThemeData(
      color: AppElegant.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppElegant.hair, width: 0.5),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppElegant.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      highlightElevation: 0,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppElegant.bgAlt,
      hintStyle: const TextStyle(color: AppElegant.inkWhisper, fontSize: 14),
      labelStyle: const TextStyle(color: AppElegant.inkSoft, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppElegant.hair, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppElegant.accent, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: AppElegant.hair,
      thickness: 0.5,
      space: 0.5,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppElegant.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppElegant.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppElegant.ink,
        side: const BorderSide(color: AppElegant.hair, width: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppElegant.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppElegant.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppElegant.ink,
        letterSpacing: 0.3,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: AppElegant.inkSoft,
        height: 1.5,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppElegant.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppElegant.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppElegant.card,
      selectedItemColor: AppElegant.accent,
      unselectedItemColor: AppElegant.inkSoft,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppElegant.bgAlt,
      labelStyle: const TextStyle(fontSize: 12, color: AppElegant.ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppElegant.hair, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppElegant.accent;
        }
        return AppElegant.hair;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}
