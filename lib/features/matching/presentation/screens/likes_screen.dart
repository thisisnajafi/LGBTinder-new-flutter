// Screen: Likesscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Likesscreen extends ConsumerStatefulWidget {
  const Likesscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Likesscreen> createState() => _LikesscreenState();
}

class _LikesscreenState extends ConsumerState<Likesscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Likesscreen'),
      ),
      body: const Center(
        child: Text('Likesscreen Screen'),
      ),
    );
  }
}
