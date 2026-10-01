# Mac and Linux wrappers. On Windows use scripts/flutter-flavor.ps1.
# Every target passes both --flavor and --target.

.PHONY: android-dev android-staging android-prod \
        apk-dev apk-staging apk-prod \
        bundle-dev bundle-staging bundle-prod \
        ios-dev ios-staging ios-prod \
        ipa-dev ipa-staging ipa-prod

android-dev:
	flutter run --flavor development --target lib/main_development.dart

android-staging:
	flutter run --flavor staging --target lib/main_staging.dart

android-prod:
	flutter run --flavor production --target lib/main_production.dart

apk-dev:
	flutter build apk --flavor development --target lib/main_development.dart

apk-staging:
	flutter build apk --flavor staging --target lib/main_staging.dart

apk-prod:
	flutter build apk --flavor production --target lib/main_production.dart

bundle-dev:
	flutter build appbundle --flavor development --target lib/main_development.dart

bundle-staging:
	flutter build appbundle --flavor staging --target lib/main_staging.dart

bundle-prod:
	flutter build appbundle --flavor production --target lib/main_production.dart

ios-dev:
	flutter run --flavor development --target lib/main_development.dart

ios-staging:
	flutter run --flavor staging --target lib/main_staging.dart

ios-prod:
	flutter run --flavor production --target lib/main_production.dart

ipa-dev:
	flutter build ipa --flavor development --target lib/main_development.dart

ipa-staging:
	flutter build ipa --flavor staging --target lib/main_staging.dart

ipa-prod:
	flutter build ipa --flavor production --target lib/main_production.dart
