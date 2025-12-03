// Screen: Profileanalyticsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Profileanalyticsscreen extends ConsumerStatefulWidget {
  const Profileanalyticsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Profileanalyticsscreen> createState() => _ProfileanalyticsscreenState();
}

class _ProfileanalyticsscreenState extends ConsumerState<Profileanalyticsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profileanalyticsscreen'),
      ),
      body: const Center(
        child: Text('Profileanalyticsscreen Screen'),
      ),
    );
  }
}
