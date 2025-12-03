// Screen: Filterscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Filterscreen extends ConsumerStatefulWidget {
  const Filterscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Filterscreen> createState() => _FilterscreenState();
}

class _FilterscreenState extends ConsumerState<Filterscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filterscreen'),
      ),
      body: const Center(
        child: Text('Filterscreen Screen'),
      ),
    );
  }
}
