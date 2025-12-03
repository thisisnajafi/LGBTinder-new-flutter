// Screen: Accessibilitysettingsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Accessibilitysettingsscreen extends ConsumerStatefulWidget {
  const Accessibilitysettingsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Accessibilitysettingsscreen> createState() => _AccessibilitysettingsscreenState();
}

class _AccessibilitysettingsscreenState extends ConsumerState<Accessibilitysettingsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibilitysettingsscreen'),
      ),
      body: const Center(
        child: Text('Accessibilitysettingsscreen Screen'),
      ),
    );
  }
}
