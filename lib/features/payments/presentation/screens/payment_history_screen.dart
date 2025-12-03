// Screen: Paymenthistoryscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Paymenthistoryscreen extends ConsumerStatefulWidget {
  const Paymenthistoryscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Paymenthistoryscreen> createState() => _PaymenthistoryscreenState();
}

class _PaymenthistoryscreenState extends ConsumerState<Paymenthistoryscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paymenthistoryscreen'),
      ),
      body: const Center(
        child: Text('Paymenthistoryscreen Screen'),
      ),
    );
  }
}
