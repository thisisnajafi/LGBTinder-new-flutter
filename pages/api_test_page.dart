// Screen: ApiTestPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiTestPage extends ConsumerStatefulWidget {
  const ApiTestPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends ConsumerState<ApiTestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ApiTestPage'),
      ),
      body: const Center(
        child: Text('ApiTestPage'),
      ),
    );
  }
}
