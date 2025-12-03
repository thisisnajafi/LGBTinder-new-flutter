// Screen: Profileeditscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Profileeditscreen extends ConsumerStatefulWidget {
  const Profileeditscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Profileeditscreen> createState() => _ProfileeditscreenState();
}

class _ProfileeditscreenState extends ConsumerState<Profileeditscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profileeditscreen'),
      ),
      body: const Center(
        child: Text('Profileeditscreen Screen'),
      ),
    );
  }
}
