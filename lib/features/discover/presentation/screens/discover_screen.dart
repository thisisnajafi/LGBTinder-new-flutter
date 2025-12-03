// Screen: Discoverscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Discoverscreen extends ConsumerStatefulWidget {
  const Discoverscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Discoverscreen> createState() => _DiscoverscreenState();
}

class _DiscoverscreenState extends ConsumerState<Discoverscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discoverscreen'),
      ),
      body: const Center(
        child: Text('Discoverscreen Screen'),
      ),
    );
  }
}
