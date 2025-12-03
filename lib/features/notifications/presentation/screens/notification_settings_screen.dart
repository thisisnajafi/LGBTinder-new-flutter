// Screen: Notificationsettingsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Notificationsettingsscreen extends ConsumerStatefulWidget {
  const Notificationsettingsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Notificationsettingsscreen> createState() => _NotificationsettingsscreenState();
}

class _NotificationsettingsscreenState extends ConsumerState<Notificationsettingsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificationsettingsscreen'),
      ),
      body: const Center(
        child: Text('Notificationsettingsscreen Screen'),
      ),
    );
  }
}
