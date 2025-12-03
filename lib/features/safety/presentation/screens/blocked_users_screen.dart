// Screen: Blockedusersscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Blockedusersscreen extends ConsumerStatefulWidget {
  const Blockedusersscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Blockedusersscreen> createState() => _BlockedusersscreenState();
}

class _BlockedusersscreenState extends ConsumerState<Blockedusersscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockedusersscreen'),
      ),
      body: const Center(
        child: Text('Blockedusersscreen Screen'),
      ),
    );
  }
}
