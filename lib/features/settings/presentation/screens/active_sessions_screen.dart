// Screen: Activesessionsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Activesessionsscreen extends ConsumerStatefulWidget {
  const Activesessionsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Activesessionsscreen> createState() => _ActivesessionsscreenState();
}

class _ActivesessionsscreenState extends ConsumerState<Activesessionsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activesessionsscreen'),
      ),
      body: const Center(
        child: Text('Activesessionsscreen Screen'),
      ),
    );
  }
}
