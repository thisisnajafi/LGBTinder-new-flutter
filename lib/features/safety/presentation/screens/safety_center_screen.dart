// Screen: Safetycenterscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Safetycenterscreen extends ConsumerStatefulWidget {
  const Safetycenterscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Safetycenterscreen> createState() => _SafetycenterscreenState();
}

class _SafetycenterscreenState extends ConsumerState<Safetycenterscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safetycenterscreen'),
      ),
      body: const Center(
        child: Text('Safetycenterscreen Screen'),
      ),
    );
  }
}
