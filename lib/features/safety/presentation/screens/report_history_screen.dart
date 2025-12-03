// Screen: Reporthistoryscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Reporthistoryscreen extends ConsumerStatefulWidget {
  const Reporthistoryscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Reporthistoryscreen> createState() => _ReporthistoryscreenState();
}

class _ReporthistoryscreenState extends ConsumerState<Reporthistoryscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporthistoryscreen'),
      ),
      body: const Center(
        child: Text('Reporthistoryscreen Screen'),
      ),
    );
  }
}
