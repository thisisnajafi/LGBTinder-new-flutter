// Screen: Voicecallscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Voicecallscreen extends ConsumerStatefulWidget {
  const Voicecallscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Voicecallscreen> createState() => _VoicecallscreenState();
}

class _VoicecallscreenState extends ConsumerState<Voicecallscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voicecallscreen'),
      ),
      body: const Center(
        child: Text('Voicecallscreen Screen'),
      ),
    );
  }
}
