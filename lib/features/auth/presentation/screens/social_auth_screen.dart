// Screen: SocialAuthScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialAuthScreen extends ConsumerStatefulWidget {
  const SocialAuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SocialAuthScreen> createState() => _SocialAuthScreenState();
}

class _SocialAuthScreenState extends ConsumerState<SocialAuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SocialAuthScreen'),
      ),
      body: const Center(
        child: Text('SocialAuthScreen Screen'),
      ),
    );
  }
}
