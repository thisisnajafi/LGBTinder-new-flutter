// Screen: Callhistoryscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Callhistoryscreen extends ConsumerStatefulWidget {
  const Callhistoryscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Callhistoryscreen> createState() => _CallhistoryscreenState();
}

class _CallhistoryscreenState extends ConsumerState<Callhistoryscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Callhistoryscreen'),
      ),
      body: const Center(
        child: Text('Callhistoryscreen Screen'),
      ),
    );
  }
}
