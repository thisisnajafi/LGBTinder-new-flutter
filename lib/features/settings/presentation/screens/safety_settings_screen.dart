// Screen: Safetysettingsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Safetysettingsscreen extends ConsumerStatefulWidget {
  const Safetysettingsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Safetysettingsscreen> createState() => _SafetysettingsscreenState();
}

class _SafetysettingsscreenState extends ConsumerState<Safetysettingsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safetysettingsscreen'),
      ),
      body: const Center(
        child: Text('Safetysettingsscreen Screen'),
      ),
    );
  }
}
