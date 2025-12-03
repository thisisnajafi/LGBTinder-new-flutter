// Screen: Paymentmethodsscreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Paymentmethodsscreen extends ConsumerStatefulWidget {
  const Paymentmethodsscreen({Key? key}) : super(key: key);

  @override
  ConsumerState<Paymentmethodsscreen> createState() => _PaymentmethodsscreenState();
}

class _PaymentmethodsscreenState extends ConsumerState<Paymentmethodsscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paymentmethodsscreen'),
      ),
      body: const Center(
        child: Text('Paymentmethodsscreen Screen'),
      ),
    );
  }
}
