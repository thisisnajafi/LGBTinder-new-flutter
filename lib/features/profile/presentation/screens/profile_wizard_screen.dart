// Screen: Profilewizardscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Profilewizardscreen extends ConsumerStatefulWidget {
  const Profilewizardscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Profilewizardscreen> createState() => _ProfilewizardscreenState();
}

class _ProfilewizardscreenState extends ConsumerState<Profilewizardscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilewizardscreen'),
      ),
      body: const Center(
        child: Text('Profilewizardscreen Screen'),
      ),
    );
  }
}
