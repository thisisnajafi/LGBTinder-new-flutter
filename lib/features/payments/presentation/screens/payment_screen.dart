// Screen: Paymentscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Paymentscreen extends ConsumerStatefulWidget {
  const Paymentscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Paymentscreen> createState() => _PaymentscreenState();
}

class _PaymentscreenState extends ConsumerState<Paymentscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paymentscreen'),
      ),
      body: const Center(
        child: Text('Paymentscreen Screen'),
      ),
    );
  }
}
