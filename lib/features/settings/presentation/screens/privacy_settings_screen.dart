// Screen: Privacysettingsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Privacysettingsscreen extends ConsumerStatefulWidget {
  const Privacysettingsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Privacysettingsscreen> createState() => _PrivacysettingsscreenState();
}

class _PrivacysettingsscreenState extends ConsumerState<Privacysettingsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacysettingsscreen'),
      ),
      body: const Center(
        child: Text('Privacysettingsscreen Screen'),
      ),
    );
  }
}
