import 'core/config/app_config.dart';
import 'main.dart';

void main() {
  try {
    AppConfig.installProduction();
  } catch (_) {
    if (!AppConfig.isReady) {
      AppConfig.installProduction(requireMatchingFlavor: false);
    }
  }
  startLgbtinderApp();
}
