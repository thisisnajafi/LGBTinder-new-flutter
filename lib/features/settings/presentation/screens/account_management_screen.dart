// Screen: Accountmanagementscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Accountmanagementscreen extends ConsumerStatefulWidget {
  const Accountmanagementscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Accountmanagementscreen> createState() => _AccountmanagementscreenState();
}

class _AccountmanagementscreenState extends ConsumerState<Accountmanagementscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountmanagementscreen'),
      ),
      body: const Center(
        child: Text('Accountmanagementscreen Screen'),
      ),
    );
  }
}
