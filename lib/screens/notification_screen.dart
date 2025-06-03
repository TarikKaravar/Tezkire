import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: const Center(
        child: Text('Bildirimler ekranı burası.'),
      ),
    );
  }
}
