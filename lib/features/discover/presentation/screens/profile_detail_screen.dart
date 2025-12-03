// Screen: Profiledetailscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Profiledetailscreen extends ConsumerStatefulWidget {
  const Profiledetailscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Profiledetailscreen> createState() => _ProfiledetailscreenState();
}

class _ProfiledetailscreenState extends ConsumerState<Profiledetailscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiledetailscreen'),
      ),
      body: const Center(
        child: Text('Profiledetailscreen Screen'),
      ),
    );
  }
}
