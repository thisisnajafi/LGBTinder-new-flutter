import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/config/app_config.dart';
import 'package:lgbtindernew/core/constants/api_endpoints.dart';

void main() {
  tearDown(AppConfig.debugReset);

  test('unconfigured endpoints stay on the production origin', () {
    expect(ApiEndpoints.apiOrigin, AppConfig.productionOrigin);
    expect(ApiEndpoints.baseUrl, '${AppConfig.productionOrigin}/api');
  });

  test('development origin on this host is loopback unless API_ORIGIN is set', () {
    expect(AppConfig.resolveDevelopmentOrigin(), AppConfig.loopbackOrigin);
  });

  test('staging refuses to start without an API origin', () {
    expect(AppConfig.resolveStagingOrigin, throwsStateError);
  });

  test('a flavor entry point rejects a missing --flavor', () {
    expect(AppConfig.installDevelopment, throwsStateError);
    expect(AppConfig.installProduction, throwsStateError);
    expect(AppConfig.isReady, isFalse);
  });

  test('bare flutter run uses the production API', () {
    AppConfig.installFromProcessFlavor();
    expect(AppConfig.isReady, isTrue);
    expect(AppConfig.current.flavor, AppFlavor.production);
    expect(AppConfig.current.apiOrigin, AppConfig.productionOrigin);
  });
}
