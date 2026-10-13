import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

void main() {
  test('cached call row with status ringing stays a success payload', () {
    final call = {
      'id': 4,
      'caller_id': 1,
      'receiver_id': 2,
      'call_type': 'audio',
      'status': 'ringing',
      'channel_name': 'call_1_2',
    };

    final response = ApiResponse.fromJson(
      call,
      (data) => Map<String, dynamic>.from(data as Map),
    );

    expect(response.isSuccess, isTrue);
    expect(response.data?['id'], 4);
    expect(response.data?['status'], 'ringing');
    expect(response.message, isEmpty);
  });

  test('success envelope still unwraps data', () {
    final response = ApiResponse.fromJson(
      {
        'success': true,
        'status': 'success',
        'message': 'Call retrieved',
        'data': {
          'id': 4,
          'status': 'active',
          'caller_id': 1,
        },
        'meta': [],
      },
      (data) => Map<String, dynamic>.from(data as Map),
    );

    expect(response.isSuccess, isTrue);
    expect(response.data?['status'], 'active');
  });
}
