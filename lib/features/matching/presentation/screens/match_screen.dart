// Screen: Matchscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Matchscreen extends ConsumerStatefulWidget {
  const Matchscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Matchscreen> createState() => _MatchscreenState();
}

class _MatchscreenState extends ConsumerState<Matchscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchscreen'),
      ),
      body: const Center(
        child: Text('Matchscreen Screen'),
      ),
    );
  }
}
