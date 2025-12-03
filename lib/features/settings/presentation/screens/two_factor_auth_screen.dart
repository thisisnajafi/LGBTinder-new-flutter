// Screen: Twofactorauthscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Twofactorauthscreen extends ConsumerStatefulWidget {
  const Twofactorauthscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Twofactorauthscreen> createState() => _TwofactorauthscreenState();
}

class _TwofactorauthscreenState extends ConsumerState<Twofactorauthscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twofactorauthscreen'),
      ),
      body: const Center(
        child: Text('Twofactorauthscreen Screen'),
      ),
    );
  }
}
