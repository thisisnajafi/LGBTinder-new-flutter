// Screen: Enhancedonboardingscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Enhancedonboardingscreen extends ConsumerStatefulWidget {
  const Enhancedonboardingscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Enhancedonboardingscreen> createState() => _EnhancedonboardingscreenState();
}

class _EnhancedonboardingscreenState extends ConsumerState<Enhancedonboardingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhancedonboardingscreen'),
      ),
      body: const Center(
        child: Text('Enhancedonboardingscreen Screen'),
      ),
    );
  }
}
