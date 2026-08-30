import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:staj/features/home/ui/main_navigation_screen.dart';
import 'package:staj/core/theme/app_colors.dart';
import 'package:staj/features/todo/todo_model.dart';
import 'package:staj/features/planner/data/models/route_model.dart';
import 'package:staj/features/planner/data/models/waypoint_model.dart';
import 'package:staj/features/badges/data/models/city_badge.dart';
import 'package:staj/features/badges/data/models/memory_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Uygulama Hatası: ${details.exception}');
  };

  await Hive.initFlutter();
  Hive.registerAdapter(TodoModelAdapter());
  Hive.registerAdapter(WaypointAdapter());
  Hive.registerAdapter(RouteModelAdapter());
  Hive.registerAdapter(CityBadgeAdapter());
  Hive.registerAdapter(MemoryItemAdapter());

  await Future.wait([
    Hive.openBox<TodoModel>('todoBox'),
    Hive.openBox('settingsBox'),
    Hive.openBox<RouteModel>('routesBox'),
    Hive.openBox<CityBadge>('badgesBox'),
    Hive.openBox<MemoryItem>('memoryBox'),
  ]);

  runApp(
    const ProviderScope(
      child: SmartTravelApp(),
    ),
  );
}

class SmartTravelApp extends StatelessWidget {
  const SmartTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akıllı Seyahat Ajandası',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}