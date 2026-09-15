// PERFORMANCE FIX (Task 7.2.3): Lazy Loading List Widget
// Efficient infinite scroll with pagination support

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../core/widgets/app_list_view.dart';

/// Callback type for loading more items
typedef LoadMoreCallback = Future<bool> Function();

/// PERFORMANCE FIX (Task 7.2.3): Lazy loading list wrapper
/// 
/// Features:
/// - Automatic pagination trigger at scroll threshold
/// - Loading indicator at bottom
/// - Empty state handling
/// - Error state handling
/// - Pull-to-refresh support
class LazyLoadList<T> extends ConsumerStatefulWidget {
  /// List of items to display
  final List<T> items;
  
  /// Builder for each item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  
  /// Callback when more items should be loaded
  final LoadMoreCallback? onLoadMore;
  
  /// Whether there are more items to load
  final bool hasMore;
  
  /// Whether currently loading more items
  final bool isLoading;
  
  /// Callback for pull-to-refresh
  final Future<void> Function()? onRefresh;
  
  /// Widget to show when list is empty
  final Widget? emptyWidget;
  
  /// Widget to show when there's an error
  final Widget? errorWidget;
  
  /// Error state
  final bool hasError;
  
  /// Scroll threshold to trigger load more (0.0 - 1.0)
  /// Default is 0.8 (80% scrolled)
  final double loadMoreThreshold;
  
  /// Separator widget between items
  final Widget? separatorWidget;
  
  /// Padding around the list
  final EdgeInsets? padding;
  
  /// Physics for the scroll view
  final ScrollPhysics? physics;
  
  /// Custom scroll controller
  final ScrollController? scrollController;

  const LazyLoadList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.onRefresh,
    this.emptyWidget,
    this.errorWidget,
    this.hasError = false,
    this.loadMoreThreshold = 0.8,
    this.separatorWidget,
    this.padding,
    this.physics,
    this.scrollController,
  });

  @override
  ConsumerState<LazyLoadList<T>> createState() => _LazyLoadListState<T>();
}

class _LazyLoadListState<T> extends ConsumerState<LazyLoadList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore || widget.isLoading) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * widget.loadMoreThreshold;
    
    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (widget.hasError && widget.errorWidget != null) {
      return widget.errorWidget!;
    }
    
    // Empty state
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildDefaultEmptyWidget();
    }
    
    // AppListView already virtualizes via slivers + default cacheExtent
    // (PERF-COMP-SHARED-001 / 002).
    Widget listView;

    if (widget.separatorWidget != null) {
      listView = AppListView.separated(
        controller: _scrollController,
        physics: widget.physics ?? AppScroll.forPlatform(context),
        padding: widget.padding,
        itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => widget.separatorWidget!,
        itemBuilder: _buildItem,
      );
    } else {
      listView = AppListView.builder(
        controller: _scrollController,
        physics: widget.physics ?? AppScroll.forPlatform(context),
        padding: widget.padding,
        itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
        itemBuilder: _buildItem,
      );
    }
    
    if (widget.onRefresh != null) {
      return PremiumRefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }
    
    return listView;
  }

  Widget _buildItem(BuildContext context, int index) {
    // Loading indicator at the end
    if (index >= widget.items.length) {
      return _buildLoadingIndicator();
    }
    
    return widget.itemBuilder(context, widget.items[index], index);
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    final muted = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(
            assetPath: AppIcons.emptyBox,
            size: 64,
            color: muted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.spacingLG),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: muted.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// PERFORMANCE FIX (Task 7.2.3): Lazy loading grid for images
/// 
/// Optimized for image galleries with consistent sizing
class LazyLoadGrid<T> extends ConsumerStatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final LoadMoreCallback? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final Widget? emptyWidget;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final double loadMoreThreshold;

  const LazyLoadGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.onRefresh,
    this.emptyWidget,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.childAspectRatio = 1.0,
    this.padding,
    this.scrollController,
    this.loadMoreThreshold = 0.8,
  });

  @override
  ConsumerState<LazyLoadGrid<T>> createState() => _LazyLoadGridState<T>();
}

class _LazyLoadGridState<T> extends ConsumerState<LazyLoadGrid<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore || widget.isLoading) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * widget.loadMoreThreshold;
    
    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildDefaultEmptyWidget();
    }

    Widget gridView = CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollCacheExtent: const ScrollCacheExtent.pixels(
        AppScroll.listCacheExtentPixels,
      ),
      slivers: [
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              crossAxisSpacing: widget.crossAxisSpacing,
              mainAxisSpacing: widget.mainAxisSpacing,
              childAspectRatio: widget.childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => widget.itemBuilder(
                context,
                widget.items[index],
                index,
              ),
              childCount: widget.items.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
            ),
          ),
        ),
        if (widget.hasMore)
          SliverToBoxAdapter(
            child: _buildLoadingIndicator(),
          ),
      ],
    );

    if (widget.onRefresh != null) {
      return PremiumRefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    final muted = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(
            assetPath: AppIcons.gallery,
            size: 64,
            color: muted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.spacingLG),
          Text(
            'No images yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: muted.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pass-through for expensive rows. Viewport slivers already skip off-screen
/// [itemBuilder] work (PERF-COMP-SHARED-001). Do not add a scroll-notification
/// VisibilityDetector — that runs on every pixel of scroll.
class LazyLoadItem extends StatelessWidget {
  final Widget child;

  const LazyLoadItem({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}


