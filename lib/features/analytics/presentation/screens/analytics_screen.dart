// Screen: Analyticsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Analyticsscreen extends ConsumerStatefulWidget {
  const Analyticsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Analyticsscreen> createState() => _AnalyticsscreenState();
}

class _AnalyticsscreenState extends ConsumerState<Analyticsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyticsscreen'),
      ),
      body: const Center(
        child: Text('Analyticsscreen Screen'),
      ),
    );
  }
}
