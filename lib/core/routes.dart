import 'package:flutter/material.dart';
import '../features/notifications/notification_details_screen.dart';
import '../features/items/item_screen.dart';
import '../features/notifications/notification_settings_screen.dart';

class AppRoutes {
  static const home = '/';
  static const notificationDetails = '/notification-details';
  static const item = '/item';
  static const notificationSettings = '/notification-settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case notificationDetails:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => NotificationDetailsScreen(payload: args),
        );

      case item:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final itemId = args['id']?.toString() ?? '';
        return MaterialPageRoute(
          builder: (_) => ItemScreen(itemId: itemId),
        );

      case notificationSettings:
        return MaterialPageRoute(
          builder: (_) => const NotificationSettingsScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const _HomeScreen(),
        );
    }
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.notificationSettings);
              },
              child: const Text('Notification settings'),
            ),
          ],
        ),
      ),
    );
  }
}
