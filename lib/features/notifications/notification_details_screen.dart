import 'package:flutter/material.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> payload;

  const NotificationDetailsScreen({
    super.key,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    final title = payload['title']?.toString() ?? 'No title';
    final body = payload['body']?.toString() ?? 'No body';

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Title: $title', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Body: $body', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Payload:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(payload.toString()),
          ],
        ),
      ),
    );
  }
}
