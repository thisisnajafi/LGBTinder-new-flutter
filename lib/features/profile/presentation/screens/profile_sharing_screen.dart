// Screen: Profilesharingscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Profilesharingscreen extends ConsumerStatefulWidget {
  const Profilesharingscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Profilesharingscreen> createState() => _ProfilesharingscreenState();
}

class _ProfilesharingscreenState extends ConsumerState<Profilesharingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilesharingscreen'),
      ),
      body: const Center(
        child: Text('Profilesharingscreen Screen'),
      ),
    );
  }
}
