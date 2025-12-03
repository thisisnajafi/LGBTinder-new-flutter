// Screen: Settingsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Settingsscreen extends ConsumerStatefulWidget {
  const Settingsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Settingsscreen> createState() => _SettingsscreenState();
}

class _SettingsscreenState extends ConsumerState<Settingsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settingsscreen'),
      ),
      body: const Center(
        child: Text('Settingsscreen Screen'),
      ),
    );
  }
}
