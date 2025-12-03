// Screen: Explorescreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Explorescreen extends ConsumerStatefulWidget {
  const Explorescreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Explorescreen> createState() => _ExplorescreenState();
}

class _ExplorescreenState extends ConsumerState<Explorescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorescreen'),
      ),
      body: const Center(
        child: Text('Explorescreen Screen'),
      ),
    );
  }
}
