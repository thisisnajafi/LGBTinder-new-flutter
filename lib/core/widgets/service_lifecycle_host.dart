import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_services_provider.dart';

/// Keeps session / realtime watches off [MaterialApp] (PERF-INFRA-012).
///
/// A sync tick must rebuild this host only — not the router subtree in
/// [MyApp.build].
class ServiceLifecycleHost extends ConsumerWidget {
  const ServiceLifecycleHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionServicesProvider);
    return child;
  }
}
