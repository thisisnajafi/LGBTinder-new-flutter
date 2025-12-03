// Screen: Profilecompletionscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Profilecompletionscreen extends ConsumerStatefulWidget {
  const Profilecompletionscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Profilecompletionscreen> createState() => _ProfilecompletionscreenState();
}

class _ProfilecompletionscreenState extends ConsumerState<Profilecompletionscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilecompletionscreen'),
      ),
      body: const Center(
        child: Text('Profilecompletionscreen Screen'),
      ),
    );
  }
}
