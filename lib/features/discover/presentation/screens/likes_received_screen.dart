// Screen: Likesreceivedscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Likesreceivedscreen extends ConsumerStatefulWidget {
  const Likesreceivedscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Likesreceivedscreen> createState() => _LikesreceivedscreenState();
}

class _LikesreceivedscreenState extends ConsumerState<Likesreceivedscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Likesreceivedscreen'),
      ),
      body: const Center(
        child: Text('Likesreceivedscreen Screen'),
      ),
    );
  }
}
