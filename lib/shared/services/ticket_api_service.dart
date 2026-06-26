import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../models/api_error.dart';
import '../models/api_response.dart';
import 'api_service.dart';

/// Support tickets API (list, get by id, create).
class TicketApiService {
  final ApiService _apiService;

  TicketApiService(this._apiService);

  void _ensureSuccess(ApiResponse<dynamic> response) {
    if (!response.isSuccess) {
      throw ApiError(
        message: response.message.isNotEmpty
            ? response.message
            : 'Support ticket request failed',
      );
    }
  }

  /// GET tickets — list tickets (paginated).
  Future<Map<String, dynamic>> getTickets({int page = 1}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.tickets,
      queryParameters: {'page': page},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    _ensureSuccess(response);
    return response.data ?? {};
  }

  /// GET tickets/:id — get a single ticket.
  Future<Map<String, dynamic>> getTicket(int ticketId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.ticketById(ticketId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    _ensureSuccess(response);
    return response.data ?? {};
  }

  /// POST tickets — create a ticket (multipart when screenshot is provided).
  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    required String situation,
    String? screenshotPath,
  }) async {
    final fields = <String, dynamic>{
      'title': title,
      'description': description,
      'situation': situation,
    };

    final ApiResponse<Map<String, dynamic>> response;
    if (screenshotPath != null && screenshotPath.isNotEmpty) {
      final fileName =
          screenshotPath.replaceAll(r'\', '/').split('/').last;
      final formData = FormData.fromMap({
        ...fields,
        'screenshot': await MultipartFile.fromFile(
          screenshotPath,
          filename: fileName,
        ),
      });
      response = await _apiService.postFormData<Map<String, dynamic>>(
        ApiEndpoints.tickets,
        data: formData,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } else {
      response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.tickets,
        data: fields,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    }

    _ensureSuccess(response);
    return response.data ?? {};
  }
}
