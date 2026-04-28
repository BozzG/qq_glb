import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/app_theme.dart';
import 'services/database_helper.dart';
import 'services/notification_service.dart';
import 'providers/schedule_provider.dart';
import 'providers/course_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/medical_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initDatabaseFactory();
  await initializeDateFormatting('zh_CN', null);
  await NotificationService().init();
  runApp(const QianqianGrowthApp());
}

class QianqianGrowthApp extends StatelessWidget {
  const QianqianGrowthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProvider()),
      ],
      child: MaterialApp(
        title: "芊芊成长日志",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
