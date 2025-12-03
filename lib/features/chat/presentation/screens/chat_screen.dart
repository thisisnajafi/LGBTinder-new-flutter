// Screen: Chatscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Chatscreen extends ConsumerStatefulWidget {
  const Chatscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends ConsumerState<Chatscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatscreen'),
      ),
      body: const Center(
        child: Text('Chatscreen Screen'),
      ),
    );
  }
}
