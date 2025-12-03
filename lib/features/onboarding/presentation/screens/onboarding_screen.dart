// Screen: Onboardingscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Onboardingscreen extends ConsumerStatefulWidget {
  const Onboardingscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Onboardingscreen> createState() => _OnboardingscreenState();
}

class _OnboardingscreenState extends ConsumerState<Onboardingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboardingscreen'),
      ),
      body: const Center(
        child: Text('Onboardingscreen Screen'),
      ),
    );
  }
}
