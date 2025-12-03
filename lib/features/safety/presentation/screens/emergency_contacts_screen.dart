// Screen: Emergencycontactsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Emergencycontactsscreen extends ConsumerStatefulWidget {
  const Emergencycontactsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Emergencycontactsscreen> createState() => _EmergencycontactsscreenState();
}

class _EmergencycontactsscreenState extends ConsumerState<Emergencycontactsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergencycontactsscreen'),
      ),
      body: const Center(
        child: Text('Emergencycontactsscreen Screen'),
      ),
    );
  }
}
