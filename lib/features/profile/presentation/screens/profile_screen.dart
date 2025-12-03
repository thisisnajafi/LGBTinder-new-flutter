// Screen: Profilescreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Profilescreen extends ConsumerStatefulWidget {
  const Profilescreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends ConsumerState<Profilescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilescreen'),
      ),
      body: const Center(
        child: Text('Profilescreen Screen'),
      ),
    );
  }
}
