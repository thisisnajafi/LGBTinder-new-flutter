// Screen: Groupchatscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Groupchatscreen extends ConsumerStatefulWidget {
  const Groupchatscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Groupchatscreen> createState() => _GroupchatscreenState();
}

class _GroupchatscreenState extends ConsumerState<Groupchatscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groupchatscreen'),
      ),
      body: const Center(
        child: Text('Groupchatscreen Screen'),
      ),
    );
  }
}
