import 'package:dio/dio.dart';
import 'package:lgbtindernew/core/constants/api_endpoints.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockDioClient extends Mock implements DioClient {}

void registerDioFallbacks() {
  registerFallbackValue(RequestOptions(path: ApiEndpoints.checkToken));
}

/// Stubs GET [ApiEndpoints.checkToken] on [client]'s [dio] instance.
void stubCheckToken(
  MockDioClient client,
  MockDio dio, {
  int statusCode = 200,
}) {
  when(() => client.dio).thenReturn(dio);
  when(() => dio.get<dynamic>(any())).thenAnswer(
    (_) async => Response<dynamic>(
      requestOptions: RequestOptions(path: ApiEndpoints.checkToken),
      statusCode: statusCode,
    ),
  );
}
