// PERFORMANCE FIX (Task 7.2.3): Lazy Loading List Widget
// Efficient infinite scroll with pagination support

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    Key? key,
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
  }) : super(key: key);

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
    
    Widget listView;
    
    if (widget.separatorWidget != null) {
      listView = ListView.separated(
        controller: _scrollController,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => widget.separatorWidget!,
        itemBuilder: _buildItem,
      );
    } else {
      listView = ListView.builder(
        controller: _scrollController,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
        itemBuilder: _buildItem,
      );
    }
    
    if (widget.onRefresh != null) {
      return RefreshIndicator(
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
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
    Key? key,
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
  }) : super(key: key);

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
              (context, index) => widget.itemBuilder(context, widget.items[index], index),
              childCount: widget.items.length,
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
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No images yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// PERFORMANCE FIX (Task 7.2.3): Visibility-based lazy loading
/// 
/// Only renders items when they become visible in the viewport.
/// Useful for expensive widgets like video players or complex cards.
class LazyLoadItem extends StatefulWidget {
  final Widget child;
  final Widget? placeholder;
  final double placeholderHeight;

  const LazyLoadItem({
    Key? key,
    required this.child,
    this.placeholder,
    this.placeholderHeight = 200,
  }) : super(key: key);

  @override
  State<LazyLoadItem> createState() => _LazyLoadItemState();
}

class _LazyLoadItemState extends State<LazyLoadItem> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: (info) {
        if (!_isVisible && info.visibleFraction > 0) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: _isVisible
          ? widget.child
          : widget.placeholder ?? SizedBox(height: widget.placeholderHeight),
    );
  }
}

/// Simple visibility detector widget
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final void Function(VisibilityInfo info) onVisibilityChanged;

  const VisibilityDetector({
    Key? key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    final RenderObject? renderObject = _key.currentContext?.findRenderObject();
    if (renderObject == null) return;

    final RenderAbstractViewport? viewport = RenderAbstractViewport.of(renderObject);
    if (viewport == null) {
      // Not in a scrollable - assume fully visible
      widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 1.0));
      return;
    }

    final RevealedOffset? revealedOffset = viewport.getOffsetToReveal(renderObject, 0.0);
    if (revealedOffset == null) return;

    final viewportSize = viewport.paintBounds.size;
    final itemSize = renderObject.paintBounds.size;
    
    // Calculate visible fraction
    double visibleFraction = 0.0;
    if (itemSize.height > 0) {
      final visible = (viewportSize.height - revealedOffset.offset.abs()).clamp(0.0, itemSize.height);
      visibleFraction = visible / itemSize.height;
    }

    widget.onVisibilityChanged(VisibilityInfo(visibleFraction: visibleFraction));
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: KeyedSubtree(
        key: _key,
        child: widget.child,
      ),
    );
  }
}

/// Visibility information for lazy loading
class VisibilityInfo {
  final double visibleFraction;

  const VisibilityInfo({required this.visibleFraction});
}


