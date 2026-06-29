import 'package:dio/dio.dart';

import '../services/app_logger.dart';
import 'subscription_meta_sync.dart';

/// Syncs subscription meta from every authenticated API response.
class SubscriptionMetaInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final meta = data['meta'];
        if (meta is Map<String, dynamic>) {
          final subscription = meta['subscription'];
          if (subscription is Map<String, dynamic>) {
            SubscriptionMetaSync.instance.handle(subscription);
          }
        }
      }
    } catch (e) {
      AppLogger.error(
        'Subscription meta parse failed',
        tag: 'SubscriptionInterceptor',
        error: e,
      );
    }

    handler.next(response);
  }
}
