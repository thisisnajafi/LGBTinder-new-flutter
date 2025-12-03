// Screen: Messagesearchscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Messagesearchscreen extends ConsumerStatefulWidget {
  const Messagesearchscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Messagesearchscreen> createState() => _MessagesearchscreenState();
}

class _MessagesearchscreenState extends ConsumerState<Messagesearchscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messagesearchscreen'),
      ),
      body: const Center(
        child: Text('Messagesearchscreen Screen'),
      ),
    );
  }
}
