import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// Support tickets API (list, get by id, create).
class TicketApiService {
  final ApiService _apiService;

  TicketApiService(this._apiService);

  /// GET tickets — list tickets (paginated). Returns data with tickets and pagination.
  Future<Map<String, dynamic>> getTickets({int page = 1}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.tickets,
      queryParameters: {'page': page},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET tickets/:id — get a single ticket.
  Future<Map<String, dynamic>> getTicket(int ticketId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.ticketById(ticketId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST tickets — create a ticket. Body: subject, message, etc.
  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.tickets,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }
}
