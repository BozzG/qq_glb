import 'package:flutter/material.dart';

class AppColors {
  // 主题色 - 温暖柔和色调
  static const Color primary = Color(0xFFE57382); // 粉红色
  static const Color primaryLight = Color(0xFFFCE4EC); // 浅粉色
  static const Color primaryDark = Color(0xFFC2185B); // 深粉色
  static const Color secondary = Color(0xFFFFB74D); // 暖黄色
  static const Color secondaryLight = Color(0xFFFFF8E1); // 浅黄色
  static const Color accent = Color(0xFF81C784); // 草绿色

  // 背景色
  static const Color background = Color(0xFFFFFBF5); // 暖白背景
  static const Color surface = Color(0xFFFFFFFF); // 卡片背景
  static const Color cardBackground = Color(0xFFFFFFFF);

  // 文字颜色
  static const Color textPrimary = Color(0xFF2D2D2D); // 主文字
  static const Color textSecondary = Color(0xFF757575); // 次要文字
  static const Color textHint = Color(0xFFBDBDBD); // 提示文字

  // 功能色
  static const Color success = Color(0xFF66BB6A); // 成功/打卡完成
  static const Color warning = Color(0xFFFFA726); // 警告/即将到期
  static const Color error = Color(0xFFEF5350); // 错误/已过期
  static const Color info = Color(0xFF42A5F5); // 信息

  // 日程类型颜色
  static const Color scheduleNursery = Color(0xFFF06292); // 托班-粉红
  static const Color scheduleSports = Color(0xFF64B5F6); // 运动课-蓝色
  static const Color scheduleLanguage = Color(0xFFBA68C8); // 语言训练课-紫色
  static const Color scheduleMedical = Color(0xFFEF5350); // 医疗-红色
  static const Color scheduleSchool = Color(0xFF66BB6A); // 上学-绿色
  static const Color scheduleGeneral = Color(0xFF90A4AE); // 通用-灰色

  // 卡通主题色板
  static final List<Color> cartoonPalette = [
    Color(0xFFFF6B9D), // 粉红
    Color(0xFFFFA07A), // 珊瑚橙
    Color(0xFF98D8C8), // 薄荷绿
    Color(0xFFBB8FCE), // 淡紫
    Color(0xFFF7DC6F), // 明黄
    Color(0xFF85C1E9), // 天蓝
  ];
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
    fontFamily: 'MaShanZheng',
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.primaryLight.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 10,
    ),
    dividerTheme: DividerThemeData(color: AppColors.primaryLight),
  );
}
