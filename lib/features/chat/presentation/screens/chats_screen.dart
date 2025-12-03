// Screen: Chatsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Chatsscreen extends ConsumerStatefulWidget {
  const Chatsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Chatsscreen> createState() => _ChatsscreenState();
}

class _ChatsscreenState extends ConsumerState<Chatsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatsscreen'),
      ),
      body: const Center(
        child: Text('Chatsscreen Screen'),
      ),
    );
  }
}
