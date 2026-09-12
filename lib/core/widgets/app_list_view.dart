import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'premium/premium_layout.dart';

/// Default virtualized list (PERF-INFRA-020).
///
/// `cacheExtent` 400, repaint boundaries on, keep-alives off so off-screen
/// rows dispose. Pass [physics] to override [AppScroll.forPlatform].
class AppListView extends StatelessWidget {
  const AppListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.physics,
    this.reverse = false,
    this.shrinkWrap = false,
    this.primary,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  }) : separatorBuilder = null;

  const AppListView.separated({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required IndexedWidgetBuilder this.separatorBuilder,
    this.controller,
    this.padding,
    this.physics,
    this.reverse = false,
    this.shrinkWrap = false,
    this.primary,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool reverse;
  final bool shrinkWrap;
  final bool? primary;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  static const double cacheExtentPixels = AppScroll.listCacheExtentPixels;

  @override
  Widget build(BuildContext context) {
    final resolvedPhysics = physics ?? AppScroll.forPlatform(context);
    const cache = ScrollCacheExtent.pixels(AppScroll.listCacheExtentPixels);
    if (separatorBuilder != null) {
      return ListView.separated(
        controller: controller,
        physics: resolvedPhysics,
        padding: padding,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        primary: primary,
        keyboardDismissBehavior: keyboardDismissBehavior,
        scrollCacheExtent: cache,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder!,
      );
    }
    return ListView.builder(
      controller: controller,
      physics: resolvedPhysics,
      padding: padding,
      reverse: reverse,
      shrinkWrap: shrinkWrap,
      primary: primary,
      keyboardDismissBehavior: keyboardDismissBehavior,
      scrollCacheExtent: cache,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
