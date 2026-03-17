import 'package:flutter/material.dart';
import 'core/routes.dart';
import 'features/notifications/notification_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notifications Demo',
      navigatorKey: navigatorKey,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.home,
    );
  }
}
