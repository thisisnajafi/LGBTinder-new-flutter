/// Paginated Response Model
/// 
/// Task 3.1.2 (Phase 4): Create unified pagination response model
/// 
/// Handles various backend pagination formats:
/// - Laravel paginate() format
/// - Custom array with separate pagination object
/// - Nested data with items/pagination keys
/// 
/// Usage:
/// ```dart
/// final response = PaginatedResponse.fromJson(
///   json,
///   (item) => User.fromJson(item),
/// );
/// print(response.items); // List<User>
/// print(response.hasMore); // true/false
/// ```

class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.hasMore = false,
  });

  /// Create PaginatedResponse from JSON
  /// 
  /// Handles multiple response formats:
  /// 1. Laravel paginate(): { data: [...], current_page, last_page, per_page, total }
  /// 2. Custom format: { status: true, data: { items: [...], pagination: {...} } }
  /// 3. Simple format: { status: true, data: [...], page: 1, total: 100, has_more: true }
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemConverter, {
    List<String>? itemsKeys,
  }) {
    List<T> parsedItems = [];
    int currentPage = 1;
    int lastPage = 1;
    int perPage = 20;
    int total = 0;
    bool hasMore = false;

    // Keys to search for items list
    final possibleItemsKeys = itemsKeys ?? [
      'data',
      'items',
      'list',
      'results',
      'notifications',
      'messages',
      'users',
      'profiles',
      'matches',
      'chats',
      'calls',
    ];

    try {
      // Extract items from various possible locations
      List<dynamic>? itemsList;
      Map<String, dynamic>? paginationData;

      // Check if this is Laravel paginate() format (data is the items array directly at root)
      if (json['data'] is List) {
        itemsList = json['data'] as List;
        paginationData = json;
      }
      // Check if data is a nested object
      else if (json['data'] is Map<String, dynamic>) {
        final dataMap = json['data'] as Map<String, dynamic>;
        
        // Look for items in nested data
        for (final key in possibleItemsKeys) {
          if (dataMap[key] is List) {
            itemsList = dataMap[key] as List;
            break;
          }
        }
        
        // Look for pagination info
        if (dataMap['pagination'] is Map<String, dynamic>) {
          paginationData = dataMap['pagination'] as Map<String, dynamic>;
        } else {
          // Pagination might be in the data map itself
          paginationData = dataMap;
        }
      }
      // Root level items
      else {
        for (final key in possibleItemsKeys) {
          if (json[key] is List) {
            itemsList = json[key] as List;
            break;
          }
        }
        paginationData = json;
      }

      // Parse items
      if (itemsList != null) {
        parsedItems = itemsList
            .where((e) => e != null)
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return itemConverter(e);
                } else if (e is Map) {
                  return itemConverter(Map<String, dynamic>.from(e));
                }
                return null;
              } catch (err) {
                // Skip invalid items
                return null;
              }
            })
            .whereType<T>()
            .toList();
      }

      // Parse pagination metadata
      if (paginationData != null) {
        currentPage = _parseInt(
          paginationData['current_page'] ?? paginationData['page'],
          defaultValue: 1,
        );
        lastPage = _parseInt(
          paginationData['last_page'] ?? paginationData['total_pages'],
          defaultValue: 1,
        );
        perPage = _parseInt(
          paginationData['per_page'] ?? paginationData['limit'],
          defaultValue: 20,
        );
        total = _parseInt(
          paginationData['total'] ?? paginationData['total_count'],
          defaultValue: parsedItems.length,
        );
        
        // Calculate hasMore
        final hasMoreValue = paginationData['has_more'] ?? paginationData['has_next'];
        if (hasMoreValue != null) {
          hasMore = hasMoreValue == true || hasMoreValue == 1;
        } else {
          hasMore = currentPage < lastPage;
        }
      }
    } catch (e) {
      // Log error but don't crash - return empty response
      print('PaginatedResponse.fromJson error: $e');
    }

    return PaginatedResponse<T>(
      items: parsedItems,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
      hasMore: hasMore,
    );
  }

  /// Create empty response
  factory PaginatedResponse.empty() {
    return PaginatedResponse<T>(
      items: [],
      currentPage: 1,
      lastPage: 1,
      perPage: 20,
      total: 0,
      hasMore: false,
    );
  }

  /// Parse int from various types
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage >= lastPage;

  /// Check if there are more pages before current
  bool get hasPrevious => currentPage > 1;

  /// Check if there are more pages after current
  bool get hasNext => hasMore || currentPage < lastPage;

  /// Get the next page number
  int get nextPage => currentPage + 1;

  /// Get the previous page number
  int get previousPage => currentPage > 1 ? currentPage - 1 : 1;

  /// Check if response is empty
  bool get isEmpty => items.isEmpty;

  /// Check if response has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get item count on current page
  int get itemCount => items.length;

  /// Create a new PaginatedResponse with appended items (for infinite scroll)
  PaginatedResponse<T> appendItems(PaginatedResponse<T> nextPage) {
    return PaginatedResponse<T>(
      items: [...items, ...nextPage.items],
      currentPage: nextPage.currentPage,
      lastPage: nextPage.lastPage,
      perPage: nextPage.perPage,
      total: nextPage.total,
      hasMore: nextPage.hasMore,
    );
  }

  /// Create a copy with updated values
  PaginatedResponse<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? lastPage,
    int? perPage,
    int? total,
    bool? hasMore,
  }) {
    return PaginatedResponse<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  String toString() {
    return 'PaginatedResponse(itemCount: ${items.length}, page: $currentPage/$lastPage, total: $total, hasMore: $hasMore)';
  }
}

