import 'package:flutter/material.dart';
import 'localization_service.dart';
import 'locale_provider.dart';

/// App localizations delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return SupportedLocales.all.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    await LocalizationService().loadLanguage(locale.languageCode);
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// App localizations class
class AppLocalizations {
  final Locale locale;
  final LocalizationService _localizationService = LocalizationService();

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  // Common translations
  String get appName => _localizationService.translate('app_name');
  String get welcome => _localizationService.translate('welcome');
  String get login => _localizationService.translate('login');
  String get logout => _localizationService.translate('logout');
  String get register => _localizationService.translate('register');
  String get email => _localizationService.translate('email');
  String get password => _localizationService.translate('password');
  String get confirmPassword => _localizationService.translate('confirm_password');
  String get forgotPassword => _localizationService.translate('forgot_password');
  String get resetPassword => _localizationService.translate('reset_password');
  String get continue_ => _localizationService.translate('continue');
  String get cancel => _localizationService.translate('cancel');
  String get save => _localizationService.translate('save');
  String get delete => _localizationService.translate('delete');
  String get edit => _localizationService.translate('edit');
  String get add => _localizationService.translate('add');
  String get remove => _localizationService.translate('remove');
  String get search => _localizationService.translate('search');
  String get filter => _localizationService.translate('filter');
  String get sort => _localizationService.translate('sort');
  String get settings => _localizationService.translate('settings');
  String get profile => _localizationService.translate('profile');
  String get home => _localizationService.translate('home');
  String get discover => _localizationService.translate('discover');
  String get matches => _localizationService.translate('matches');
  String get messages => _localizationService.translate('messages');
  String get notifications => _localizationService.translate('notifications');
  String get privacy => _localizationService.translate('privacy');
  String get terms => _localizationService.translate('terms');
  String get help => _localizationService.translate('help');
  String get about => _localizationService.translate('about');
  String get contact => _localizationService.translate('contact');
  String get feedback => _localizationService.translate('feedback');
  String get report => _localizationService.translate('report');
  String get block => _localizationService.translate('block');
  String get unblock => _localizationService.translate('unblock');
  String get like => _localizationService.translate('like');
  String get superLike => _localizationService.translate('super_like');
  String get pass => _localizationService.translate('pass');
  String get match => _localizationService.translate('match');
  String get chat => _localizationService.translate('chat');
  String get send => _localizationService.translate('send');
  String get sent => _localizationService.translate('sent');
  String get received => _localizationService.translate('received');
  String get online => _localizationService.translate('online');
  String get offline => _localizationService.translate('offline');
  String get lastSeen => _localizationService.translate('last_seen');
  String get typing => _localizationService.translate('typing');
  String get photo => _localizationService.translate('photo');
  String get video => _localizationService.translate('video');
  String get location => _localizationService.translate('location');
  String get age => _localizationService.translate('age');
  String get gender => _localizationService.translate('gender');
  String get interests => _localizationService.translate('interests');
  String get bio => _localizationService.translate('bio');
  String get distance => _localizationService.translate('distance');
  String get height => _localizationService.translate('height');
  String get weight => _localizationService.translate('weight');
  String get education => _localizationService.translate('education');
  String get occupation => _localizationService.translate('occupation');
  String get religion => _localizationService.translate('religion');
  String get politics => _localizationService.translate('politics');
  String get drinking => _localizationService.translate('drinking');
  String get smoking => _localizationService.translate('smoking');
  String get children => _localizationService.translate('children');
  String get pets => _localizationService.translate('pets');
  String get zodiac => _localizationService.translate('zodiac');
  String get language => _localizationService.translate('language');
  String get error => _localizationService.translate('error');
  String get success => _localizationService.translate('success');
  String get warning => _localizationService.translate('warning');
  String get info => _localizationService.translate('info');
  String get loading => _localizationService.translate('loading');
  String get retry => _localizationService.translate('retry');
  String get refresh => _localizationService.translate('refresh');
  String get update => _localizationService.translate('update');
  String get upgrade => _localizationService.translate('upgrade');
  String get premium => _localizationService.translate('premium');
  String get subscription => _localizationService.translate('subscription');
  String get payment => _localizationService.translate('payment');
  String get billing => _localizationService.translate('billing');
  String get invoice => _localizationService.translate('invoice');
  String get receipt => _localizationService.translate('receipt');

  // Onboarding specific translations
  String get onboardingWelcome => _localizationService.translate('onboarding_welcome');
  String get onboardingGetStarted => _localizationService.translate('onboarding_get_started');
  String get onboardingSkip => _localizationService.translate('onboarding_skip');
  String get onboardingComplete => _localizationService.translate('onboarding_complete');
  String get onboardingNext => _localizationService.translate('onboarding_next');
  String get onboardingPrevious => _localizationService.translate('onboarding_previous');
  String get onboardingFinish => _localizationService.translate('onboarding_finish');

  // Error messages
  String get errorNetwork => _localizationService.translate('error_network');
  String get errorServer => _localizationService.translate('error_server');
  String get errorUnknown => _localizationService.translate('error_unknown');
  String get errorValidation => _localizationService.translate('error_validation');
  String get errorAuthentication => _localizationService.translate('error_authentication');
  String get errorAuthorization => _localizationService.translate('error_authorization');
  String get errorNotFound => _localizationService.translate('error_not_found');
  String get errorConflict => _localizationService.translate('error_conflict');
  String get errorTooManyRequests => _localizationService.translate('error_too_many_requests');

  // Validation messages
  String get validationRequired => _localizationService.translate('validation_required');
  String get validationEmail => _localizationService.translate('validation_email');
  String get validationPassword => _localizationService.translate('validation_password');
  String get validationPasswordConfirm => _localizationService.translate('validation_password_confirm');
  String get validationMinLength => _localizationService.translate('validation_min_length');
  String get validationMaxLength => _localizationService.translate('validation_max_length');

  // Dynamic translations with parameters
  String translate(String key, {Map<String, String>? params}) {
    return _localizationService.translate(key, params: params);
  }

  String plural(String key, int count, {Map<String, String>? params}) {
    return _localizationService.plural(key, count, params: params);
  }

  // Get current locale
  Locale get currentLocale => locale;

  // Check if current language is RTL
  bool get isRTL => _localizationService.isRTL;

  // Get text direction
  TextDirection get textDirection => _localizationService.textDirection;
}
