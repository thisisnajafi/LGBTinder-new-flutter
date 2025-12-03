// Screen: Profileverificationscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Profileverificationscreen extends ConsumerStatefulWidget {
  const Profileverificationscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Profileverificationscreen> createState() => _ProfileverificationscreenState();
}

class _ProfileverificationscreenState extends ConsumerState<Profileverificationscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profileverificationscreen'),
      ),
      body: const Center(
        child: Text('Profileverificationscreen Screen'),
      ),
    );
  }
}
