/// Localization constants and configuration
class LocalizationConstants {
  /// Supported languages with their codes
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ar': 'العربية',
    'hi': 'हिंदी',
  };

  /// RTL (Right-to-Left) languages
  static const List<String> rtlLanguages = [
    'ar', // Arabic
    'he', // Hebrew
    'fa', // Persian/Farsi
    'ur', // Urdu
    'yi', // Yiddish
  ];

  /// Languages that use different numeral systems
  static const Map<String, String> numeralSystems = {
    'ar': 'arab', // Arabic-Indic numerals
    'fa': 'arab', // Persian numerals
    'hi': 'deva', // Devanagari numerals
    'bn': 'beng', // Bengali numerals
    'th': 'thai', // Thai numerals
  };

  /// Date format patterns for different locales
  static const Map<String, String> dateFormats = {
    'en': 'MM/dd/yyyy',
    'es': 'dd/MM/yyyy',
    'fr': 'dd/MM/yyyy',
    'de': 'dd.MM.yyyy',
    'it': 'dd/MM/yyyy',
    'pt': 'dd/MM/yyyy',
    'ru': 'dd.MM.yyyy',
    'zh': 'yyyy年MM月dd日',
    'ja': 'yyyy年MM月dd日',
    'ko': 'yyyy년 MM월 dd일',
    'ar': 'dd/MM/yyyy',
    'hi': 'dd/MM/yyyy',
  };

  /// Time format patterns for different locales
  static const Map<String, String> timeFormats = {
    'en': 'h:mm a',
    'es': 'H:mm',
    'fr': 'HH:mm',
    'de': 'HH:mm',
    'it': 'HH:mm',
    'pt': 'HH:mm',
    'ru': 'HH:mm',
    'zh': 'HH:mm',
    'ja': 'HH:mm',
    'ko': 'HH:mm',
    'ar': 'HH:mm',
    'hi': 'HH:mm',
  };

  /// Currency symbols for different locales
  static const Map<String, String> currencySymbols = {
    'en': '\$',
    'es': '€',
    'fr': '€',
    'de': '€',
    'it': '€',
    'pt': '€',
    'ru': '₽',
    'zh': '¥',
    'ja': '¥',
    'ko': '₩',
    'ar': 'ر.س',
    'hi': '₹',
  };

  /// Distance units for different locales
  static const Map<String, String> distanceUnits = {
    'en': 'mi', // miles
    'es': 'km',
    'fr': 'km',
    'de': 'km',
    'it': 'km',
    'pt': 'km',
    'ru': 'km',
    'zh': 'km',
    'ja': 'km',
    'ko': 'km',
    'ar': 'km',
    'hi': 'km',
  };

  /// Temperature units for different locales
  static const Map<String, String> temperatureUnits = {
    'en': '°F',
    'es': '°C',
    'fr': '°C',
    'de': '°C',
    'it': '°C',
    'pt': '°C',
    'ru': '°C',
    'zh': '°C',
    'ja': '°C',
    'ko': '°C',
    'ar': '°C',
    'hi': '°C',
  };

  /// Plural rules for different languages
  static const Map<String, String> pluralRules = {
    'en': 'english',
    'es': 'spanish',
    'fr': 'french',
    'de': 'german',
    'it': 'italian',
    'pt': 'portuguese',
    'ru': 'russian',
    'zh': 'chinese',
    'ja': 'japanese',
    'ko': 'korean',
    'ar': 'arabic',
    'hi': 'hindi',
  };

  /// App-specific constants that need localization
  static const Map<String, Map<String, String>> appConstants = {
    'maxNameLength': {
      'en': '50',
      'es': '50',
      'fr': '50',
      'de': '50',
      'it': '50',
      'pt': '50',
      'ru': '50',
      'zh': '20',
      'ja': '20',
      'ko': '20',
      'ar': '50',
      'hi': '50',
    },
    'maxBioLength': {
      'en': '500',
      'es': '500',
      'fr': '500',
      'de': '500',
      'it': '500',
      'pt': '500',
      'ru': '500',
      'zh': '200',
      'ja': '200',
      'ko': '200',
      'ar': '500',
      'hi': '500',
    },
  };

  /// Validation messages that need localization
  static const Map<String, Map<String, String>> validationMessages = {
    'required': {
      'en': 'This field is required',
      'es': 'Este campo es obligatorio',
      'fr': 'Ce champ est obligatoire',
      'de': 'Dieses Feld ist erforderlich',
      'it': 'Questo campo è obbligatorio',
      'pt': 'Este campo é obrigatório',
      'ru': 'Это поле обязательно',
      'zh': '此字段为必填项',
      'ja': 'このフィールドは必須です',
      'ko': '이 필드는 필수입니다',
      'ar': 'هذا الحقل مطلوب',
      'hi': 'यह फ़ील्ड आवश्यक है',
    },
    'email': {
      'en': 'Please enter a valid email address',
      'es': 'Por favor ingrese una dirección de correo electrónico válida',
      'fr': 'Veuillez saisir une adresse email valide',
      'de': 'Bitte geben Sie eine gültige E-Mail-Adresse ein',
      'it': 'Si prega di inserire un indirizzo email valido',
      'pt': 'Por favor insira um endereço de email válido',
      'ru': 'Пожалуйста, введите действительный адрес электронной почты',
      'zh': '请输入有效的电子邮件地址',
      'ja': '有効なメールアドレスを入力してください',
      'ko': '유효한 이메일 주소를 입력하세요',
      'ar': 'يرجى إدخال عنوان بريد إلكتروني صالح',
      'hi': 'कृपया एक वैध ईमेल पता दर्ज करें',
    },
  };
}

/// Extension methods for localization
extension LocalizationExtensions on String {
  /// Get localized validation message
  String getLocalizedValidationMessage(String languageCode) {
    final messages = LocalizationConstants.validationMessages[this];
    if (messages != null) {
      return messages[languageCode] ?? messages['en'] ?? this;
    }
    return this;
  }

  /// Get localized app constant
  String getLocalizedAppConstant(String languageCode) {
    final constants = LocalizationConstants.appConstants[this];
    if (constants != null) {
      return constants[languageCode] ?? constants['en'] ?? this;
    }
    return this;
  }
}
