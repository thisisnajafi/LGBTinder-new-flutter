/// Response Helper - Standardized API response parsing
/// 
/// Task 2.1.3 (Phase 3): Create standardized response helper for consistent
/// parsing across all Flutter services.
/// 
/// Usage:
/// ```dart
/// // Extract single object from response
/// final user = ResponseHelper.extractData<User>(response.data, User.fromJson);
/// 
/// // Extract list from response
/// final messages = ResponseHelper.extractList<Message>(response.data, Message.fromJson);
/// 
/// // Check response status
/// final isSuccess = ResponseHelper.isSuccessResponse(response.data);
/// ```

class ResponseHelper {
  /// Extract data from API response, handling nested 'data' field
  /// 
  /// Handles:
  /// - Direct data: `{id: 1, name: 'User'}`
  /// - Wrapped data: `{status: true, data: {id: 1, name: 'User'}}`
  /// - Wrapped with message: `{status: 'success', message: 'OK', data: {...}}`
  static T? extractData<T>(dynamic responseData, T Function(Map<String, dynamic>) converter) {
    if (responseData == null) return null;
    
    try {
      if (responseData is Map<String, dynamic>) {
        // Check for nested 'data' field
        if (responseData.containsKey('data') && responseData['data'] != null) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            return converter(data);
          } else if (data is Map) {
            return converter(Map<String, dynamic>.from(data));
          }
        }
        
        // Check if response itself is the data (no wrapper)
        // Heuristic: If it has common API wrapper keys, unwrap it first
        final hasWrapperKeys = responseData.containsKey('status') || 
                               responseData.containsKey('message') ||
                               responseData.containsKey('success');
        
        if (!hasWrapperKeys) {
          return converter(responseData);
        }
        
        // Has wrapper but no data field - might be an error or empty response
        return null;
      }
      
      // If it's directly a convertible type
      return null;
    } catch (e) {
      // Log error for debugging
      print('ResponseHelper.extractData error: $e');
      return null;
    }
  }
  
  /// Extract list from API response, handling various nested structures
  /// 
  /// Handles:
  /// - Direct list: `[{id: 1}, {id: 2}]`
  /// - Wrapped: `{status: true, data: [{id: 1}, {id: 2}]}`
  /// - Nested: `{status: true, data: {items: [{id: 1}]}}`
  /// - Paginated: `{status: true, data: {notifications: [{...}], pagination: {...}}}`
  static List<T> extractList<T>(
    dynamic responseData, 
    T Function(Map<String, dynamic>) converter, {
    List<String>? possibleListKeys,
  }) {
    if (responseData == null) return [];
    
    // Default keys to search for list data
    final listKeys = possibleListKeys ?? [
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
      'plans',
      'subscriptions',
      'images',
      'data', // For nested data.data structures
    ];
    
    try {
      List<dynamic>? dataList;
      
      if (responseData is List) {
        dataList = responseData;
      } else if (responseData is Map<String, dynamic>) {
        // Check if data field is directly a list
        if (responseData['data'] is List) {
          dataList = responseData['data'] as List;
        } else if (responseData['data'] is Map<String, dynamic>) {
          // Search in nested data object
          final dataMap = responseData['data'] as Map<String, dynamic>;
          
          for (final key in listKeys) {
            if (dataMap.containsKey(key) && dataMap[key] is List) {
              dataList = dataMap[key] as List;
              break;
            }
          }
          
          // If still not found, check if data itself contains items matching model structure
          if (dataList == null && dataMap.isNotEmpty) {
            // Last resort: iterate values to find first List
            for (final value in dataMap.values) {
              if (value is List && value.isNotEmpty) {
                dataList = value;
                break;
              }
            }
          }
        } else if (responseData['data'] is Map) {
          // Handle Map that isn't Map<String, dynamic>
          final dataMap = Map<String, dynamic>.from(responseData['data'] as Map);
          for (final key in listKeys) {
            if (dataMap.containsKey(key) && dataMap[key] is List) {
              dataList = dataMap[key] as List;
              break;
            }
          }
        }
        
        // If no data wrapper, check root for list keys
        if (dataList == null) {
          for (final key in listKeys) {
            if (responseData.containsKey(key) && responseData[key] is List) {
              dataList = responseData[key] as List;
              break;
            }
          }
        }
      }
      
      if (dataList == null) return [];
      
      // Convert list items, skipping invalid entries
      return dataList
          .where((e) => e != null)
          .map((e) {
            try {
              if (e is Map<String, dynamic>) {
                return converter(e);
              } else if (e is Map) {
                return converter(Map<String, dynamic>.from(e));
              }
              return null;
            } catch (e) {
              // Skip invalid entries instead of crashing
              print('ResponseHelper.extractList: skipping invalid item: $e');
              return null;
            }
          })
          .whereType<T>()
          .toList();
    } catch (e) {
      print('ResponseHelper.extractList error: $e');
      return [];
    }
  }
  
  /// Check if API response indicates success
  /// 
  /// Handles:
  /// - Boolean status: `{status: true}`
  /// - String status: `{status: 'success'}`
  /// - Success field: `{success: true}`
  static bool isSuccessResponse(dynamic responseData) {
    if (responseData == null) return false;
    
    if (responseData is Map<String, dynamic>) {
      // Check 'status' field
      final status = responseData['status'];
      if (status != null) {
        if (status is bool) return status;
        if (status is String) {
          return status.toLowerCase() == 'success' || status.toLowerCase() == 'true';
        }
        if (status is int) return status == 1;
      }
      
      // Check 'success' field
      final success = responseData['success'];
      if (success != null) {
        if (success is bool) return success;
        if (success is String) {
          return success.toLowerCase() == 'true' || success == '1';
        }
        if (success is int) return success == 1;
      }
      
      // If no status indicators but has data, consider it success
      if (responseData.containsKey('data') && responseData['data'] != null) {
        return true;
      }
    }
    
    // Non-map responses are typically raw data (success)
    return true;
  }
  
  /// Extract error message from API response
  static String? extractErrorMessage(dynamic responseData) {
    if (responseData == null) return null;
    
    if (responseData is Map<String, dynamic>) {
      // Common error message fields
      return responseData['message']?.toString() ??
             responseData['error']?.toString() ??
             responseData['errors']?.toString();
    }
    
    return null;
  }
  
  /// Extract pagination info from API response
  static PaginationInfo? extractPagination(dynamic responseData) {
    if (responseData == null) return null;
    
    if (responseData is Map<String, dynamic>) {
      // Check for pagination field
      final pagination = responseData['pagination'] ?? 
                         responseData['meta'] ?? 
                         responseData['paging'];
      
      if (pagination is Map<String, dynamic>) {
        return PaginationInfo.fromJson(pagination);
      }
      
      // Check in data wrapper
      if (responseData['data'] is Map<String, dynamic>) {
        final dataMap = responseData['data'] as Map<String, dynamic>;
        final nestedPagination = dataMap['pagination'] ?? dataMap['meta'];
        if (nestedPagination is Map<String, dynamic>) {
          return PaginationInfo.fromJson(nestedPagination);
        }
      }
      
      // Check for flat pagination fields
      if (responseData.containsKey('page') || 
          responseData.containsKey('total') || 
          responseData.containsKey('has_more')) {
        return PaginationInfo.fromJson(responseData);
      }
    }
    
    return null;
  }
  
  /// Extract count/total from API response
  static int extractCount(dynamic responseData, {int defaultValue = 0}) {
    if (responseData == null) return defaultValue;
    
    if (responseData is Map<String, dynamic>) {
      // Common count fields
      final countFields = ['count', 'total', 'total_count', 'unread_count'];
      
      for (final field in countFields) {
        final value = responseData[field];
        if (value != null) {
          if (value is int) return value;
          if (value is num) return value.toInt();
          if (value is String) return int.tryParse(value) ?? defaultValue;
        }
      }
      
      // Check in data wrapper
      if (responseData['data'] is Map<String, dynamic>) {
        final dataMap = responseData['data'] as Map<String, dynamic>;
        for (final field in countFields) {
          final value = dataMap[field];
          if (value != null) {
            if (value is int) return value;
            if (value is num) return value.toInt();
            if (value is String) return int.tryParse(value) ?? defaultValue;
          }
        }
      }
    }
    
    return defaultValue;
  }
}

/// Pagination info extracted from API response
class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;
  
  PaginationInfo({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.hasMore = false,
  });
  
  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    final currentPage = _parseInt(json['current_page'] ?? json['page'], defaultValue: 1);
    final lastPage = _parseInt(json['last_page'] ?? json['total_pages'], defaultValue: 1);
    
    return PaginationInfo(
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: _parseInt(json['per_page'] ?? json['limit'], defaultValue: 20),
      total: _parseInt(json['total'] ?? json['total_count'], defaultValue: 0),
      hasMore: json['has_more'] == true || 
               json['has_more'] == 1 || 
               json['has_next'] == true ||
               currentPage < lastPage,
    );
  }
  
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  bool get hasPrevious => currentPage > 1;
  bool get hasNext => hasMore || currentPage < lastPage;
}

