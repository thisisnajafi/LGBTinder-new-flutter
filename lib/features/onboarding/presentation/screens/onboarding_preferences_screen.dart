// Screen: Onboardingpreferencesscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Onboardingpreferencesscreen extends ConsumerStatefulWidget {
  const Onboardingpreferencesscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Onboardingpreferencesscreen> createState() => _OnboardingpreferencesscreenState();
}

class _OnboardingpreferencesscreenState extends ConsumerState<Onboardingpreferencesscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboardingpreferencesscreen'),
      ),
      body: const Center(
        child: Text('Onboardingpreferencesscreen Screen'),
      ),
    );
  }
}
