// Screen: Videocallscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Videocallscreen extends ConsumerStatefulWidget {
  const Videocallscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Videocallscreen> createState() => _VideocallscreenState();
}

class _VideocallscreenState extends ConsumerState<Videocallscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videocallscreen'),
      ),
      body: const Center(
        child: Text('Videocallscreen Screen'),
      ),
    );
  }
}
