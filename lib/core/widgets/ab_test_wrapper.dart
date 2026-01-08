import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ab_testing_service.dart';

/// A/B Test Wrapper Widget
/// Wraps widgets to show different variations based on A/B test
/// Part of the Marketing System Implementation (Task 9.2.2)
class ABTestWrapper extends ConsumerStatefulWidget {
  final String featureKey;
  final Widget Function(Map<String, dynamic>? config) controlBuilder;
  final Widget Function(Map<String, dynamic>? config) variationBuilder;
  final Widget? loadingWidget;
  final Widget? fallbackWidget;
  final bool trackView;

  const ABTestWrapper({
    Key? key,
    required this.featureKey,
    required this.controlBuilder,
    required this.variationBuilder,
    this.loadingWidget,
    this.fallbackWidget,
    this.trackView = true,
  }) : super(key: key);

  @override
  ConsumerState<ABTestWrapper> createState() => _ABTestWrapperState();
}

class _ABTestWrapperState extends ConsumerState<ABTestWrapper> {
  Map<String, dynamic>? _variation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVariation();
  }

  Future<void> _loadVariation() async {
    try {
      final service = ref.read(abTestingServiceProvider);
      final variation = await service.getVariation(widget.featureKey);
      
      setState(() {
        _variation = variation;
        _isLoading = false;
      });

      // Track view if enabled
      if (widget.trackView && variation != null) {
        await service.trackView(widget.featureKey);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? const SizedBox.shrink();
    }

    // Determine which variation to show
    final variationType = _variation?['variation_type'] ?? 'control';
    final config = _variation?['configuration'] as Map<String, dynamic>?;

    if (variationType == 'control') {
      return widget.controlBuilder(config);
    } else {
      return widget.variationBuilder(config);
    }
  }
}

/// Simplified A/B Test Widget for boolean features
class ABTestFeature extends ConsumerWidget {
  final String featureKey;
  final Widget enabledWidget;
  final Widget disabledWidget;
  final bool defaultValue;

  const ABTestFeature({
    Key? key,
    required this.featureKey,
    required this.enabledWidget,
    required this.disabledWidget,
    this.defaultValue = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ABTestWrapper(
      featureKey: featureKey,
      controlBuilder: (config) {
        final enabled = config?['enabled'] ?? defaultValue;
        return enabled ? enabledWidget : disabledWidget;
      },
      variationBuilder: (config) {
        final enabled = config?['enabled'] ?? defaultValue;
        return enabled ? enabledWidget : disabledWidget;
      },
    );
  }
}

/// A/B Test Value Widget - Returns a value based on test variation
class ABTestValue<T> extends ConsumerStatefulWidget {
  final String featureKey;
  final T defaultValue;
  final Widget Function(T value) builder;
  final String valueKey;

  const ABTestValue({
    Key? key,
    required this.featureKey,
    required this.defaultValue,
    required this.builder,
    this.valueKey = 'value',
  }) : super(key: key);

  @override
  ConsumerState<ABTestValue<T>> createState() => _ABTestValueState<T>();
}

class _ABTestValueState<T> extends ConsumerState<ABTestValue<T>> {
  T? _value;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    try {
      final service = ref.read(abTestingServiceProvider);
      final variation = await service.getVariation(widget.featureKey);
      
      setState(() {
        if (variation != null) {
          final config = variation['configuration'] as Map<String, dynamic>?;
          _value = config?[widget.valueKey] as T? ?? widget.defaultValue;
        } else {
          _value = widget.defaultValue;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _value = widget.defaultValue;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.builder(widget.defaultValue);
    }

    return widget.builder(_value ?? widget.defaultValue);
  }
}
