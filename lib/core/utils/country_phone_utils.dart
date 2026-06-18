import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../features/reference_data/data/models/reference_item.dart';

/// Parsed phone payload used across forms and API submission.
class ParsedPhone {
  final String e164;
  final String nationalDigits;
  final String formattedNational;
  final String dialCode;
  final IsoCode isoCode;

  const ParsedPhone({
    required this.e164,
    required this.nationalDigits,
    required this.formattedNational,
    required this.dialCode,
    required this.isoCode,
  });
}

/// Country-aware phone validation, formatting, and E.164 conversion.
class CountryPhoneUtils {
  CountryPhoneUtils._();

  static final RegExp _nonDigits = RegExp(r'\D');

  static String digitsOnly(String value) => value.replaceAll(_nonDigits, '');

  static String normalizeDialCode(String? value, {String fallback = '+1'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;
    return trimmed.startsWith('+') ? trimmed : '+$trimmed';
  }

  /// Resolve ISO-3166 alpha-2 from reference data.
  static IsoCode? isoFromCountry(ReferenceItem? country) {
    final code = country?.code?.trim().toUpperCase();
    if (code == null || code.length != 2) return null;
    return _isoFromAlpha2(code);
  }

  static IsoCode? _isoFromAlpha2(String alpha2) {
    try {
      return IsoCode.values.firstWhere((iso) => iso.name == alpha2);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort ISO resolution when only dial code is known (+1 defaults to US).
  static IsoCode isoFromDialCode(String? dialCode) {
    final normalized = normalizeDialCode(dialCode);
    const dialToIso = {
      '+1': IsoCode.US,
      '+7': IsoCode.RU,
      '+20': IsoCode.EG,
      '+27': IsoCode.ZA,
      '+30': IsoCode.GR,
      '+31': IsoCode.NL,
      '+32': IsoCode.BE,
      '+33': IsoCode.FR,
      '+34': IsoCode.ES,
      '+36': IsoCode.HU,
      '+39': IsoCode.IT,
      '+40': IsoCode.RO,
      '+41': IsoCode.CH,
      '+43': IsoCode.AT,
      '+44': IsoCode.GB,
      '+45': IsoCode.DK,
      '+46': IsoCode.SE,
      '+47': IsoCode.NO,
      '+48': IsoCode.PL,
      '+49': IsoCode.DE,
      '+51': IsoCode.PE,
      '+52': IsoCode.MX,
      '+53': IsoCode.CU,
      '+54': IsoCode.AR,
      '+55': IsoCode.BR,
      '+56': IsoCode.CL,
      '+57': IsoCode.CO,
      '+58': IsoCode.VE,
      '+60': IsoCode.MY,
      '+61': IsoCode.AU,
      '+62': IsoCode.ID,
      '+63': IsoCode.PH,
      '+64': IsoCode.NZ,
      '+65': IsoCode.SG,
      '+66': IsoCode.TH,
      '+81': IsoCode.JP,
      '+82': IsoCode.KR,
      '+84': IsoCode.VN,
      '+86': IsoCode.CN,
      '+90': IsoCode.TR,
      '+91': IsoCode.IN,
      '+92': IsoCode.PK,
      '+93': IsoCode.AF,
      '+94': IsoCode.LK,
      '+95': IsoCode.MM,
      '+98': IsoCode.IR,
      '+212': IsoCode.MA,
      '+213': IsoCode.DZ,
      '+234': IsoCode.NG,
      '+254': IsoCode.KE,
      '+351': IsoCode.PT,
      '+352': IsoCode.LU,
      '+353': IsoCode.IE,
      '+354': IsoCode.IS,
      '+355': IsoCode.AL,
      '+356': IsoCode.MT,
      '+357': IsoCode.CY,
      '+358': IsoCode.FI,
      '+359': IsoCode.BG,
      '+370': IsoCode.LT,
      '+371': IsoCode.LV,
      '+372': IsoCode.EE,
      '+380': IsoCode.UA,
      '+381': IsoCode.RS,
      '+385': IsoCode.HR,
      '+386': IsoCode.SI,
      '+420': IsoCode.CZ,
      '+421': IsoCode.SK,
      '+852': IsoCode.HK,
      '+886': IsoCode.TW,
      '+966': IsoCode.SA,
      '+971': IsoCode.AE,
      '+972': IsoCode.IL,
      '+974': IsoCode.QA,
    };

    if (dialToIso.containsKey(normalized)) {
      return dialToIso[normalized]!;
    }

    // Longest-prefix match for shared codes like +358, +971, etc.
    IsoCode? bestMatch;
    var bestLength = 0;
    for (final entry in dialToIso.entries) {
      if (normalized.startsWith(entry.key) && entry.key.length > bestLength) {
        bestMatch = entry.value;
        bestLength = entry.key.length;
      }
    }
    return bestMatch ?? IsoCode.US;
  }

  static IsoCode resolveIso({
    ReferenceItem? country,
    String? dialCode,
  }) {
    return isoFromCountry(country) ?? isoFromDialCode(dialCode);
  }

  static String dialCodeForCountry(ReferenceItem? country, {String fallback = '+1'}) {
    final fromCountry = country?.phoneCode?.trim();
    if (fromCountry != null && fromCountry.isNotEmpty) {
      return normalizeDialCode(fromCountry, fallback: fallback);
    }
    final iso = isoFromCountry(country);
    if (iso != null) {
      try {
        final sample = PhoneNumber.parse('1', destinationCountry: iso);
        return '+${sample.countryCode}';
      } catch (_) {}
    }
    return fallback;
  }

  /// Example national format shown as placeholder (e.g. (202) 555-0123).
  static String exampleNationalHint(IsoCode iso) {
    try {
      final sampleDigits = _sampleDigitsFor(iso);
      final sample = PhoneNumber.parse(sampleDigits, destinationCountry: iso);
      return sample.formatNsn();
    } catch (_) {
      return 'Enter phone number';
    }
  }

  static String _sampleDigitsFor(IsoCode iso) {
    switch (iso) {
      case IsoCode.US:
      case IsoCode.CA:
        return '2025550123';
      case IsoCode.GB:
        return '7400123456';
      case IsoCode.NZ:
        return '211234567';
      case IsoCode.AU:
        return '412345678';
      case IsoCode.DE:
        return '1512345678';
      case IsoCode.FR:
        return '612345678';
      case IsoCode.IN:
        return '9876543210';
      default:
        return '1234567890';
    }
  }

  /// Maximum national digit count for [iso] (from libphonenumber metadata).
  static int maxNationalDigits(IsoCode iso) {
    var max = 0;
    for (var len = 1; len <= 17; len++) {
      try {
        final phone = PhoneNumber.parse('1' * len, destinationCountry: iso);
        if (phone.isValidLength()) max = len;
      } catch (_) {}
    }
    return max > 0 ? max : 15;
  }

  static bool _isAcceptableNational(PhoneNumber phone) =>
      phone.isValid() || phone.isValidLength();

  /// Format partial or complete national input using libphonenumber metadata.
  static String formatPartial(String input, IsoCode iso) {
    var digits = digitsOnly(input);
    if (digits.isEmpty) return '';

    final maxLen = maxNationalDigits(iso);
    if (digits.length > maxLen) {
      digits = digits.substring(0, maxLen);
    }

    try {
      final phone = PhoneNumber.parse(digits, destinationCountry: iso);
      return phone.formatNsn();
    } catch (_) {
      return digits;
    }
  }

  static String? validateNational(
    String? value,
    IsoCode iso, {
    bool required = true,
  }) {
    final digits = digitsOnly(value ?? '');
    if (digits.isEmpty) {
      return required ? 'Phone number is required' : null;
    }

    try {
      final phone = PhoneNumber.parse(digits, destinationCountry: iso);
      if (!_isAcceptableNational(phone)) {
        return 'Enter a valid ${iso.name} phone number';
      }
      return null;
    } catch (_) {
      return 'Enter a valid phone number';
    }
  }

  static String? validateDialCode(String? value) {
    final normalized = normalizeDialCode(value, fallback: '');
    if (normalized.isEmpty) return 'Country code is required';
    if (!RegExp(r'^\+[1-9]\d{0,3}$').hasMatch(normalized)) {
      return 'Enter a valid country code (e.g. +1, +44)';
    }
    return null;
  }

  static ParsedPhone? tryBuildFromNational({
    required String nationalInput,
    required IsoCode iso,
    String? dialCode,
  }) {
    final digits = digitsOnly(nationalInput);
    if (digits.isEmpty) return null;

    try {
      final phone = PhoneNumber.parse(digits, destinationCountry: iso);
      if (!_isAcceptableNational(phone)) return null;
      final e164 = phone.international.replaceAll(' ', '');
      return ParsedPhone(
        e164: e164,
        nationalDigits: phone.nsn,
        formattedNational: phone.formatNsn(),
        dialCode: dialCode ?? '+${phone.countryCode}',
        isoCode: phone.isoCode,
      );
    } catch (_) {
      return null;
    }
  }

  static ParsedPhone parseInternational(String raw, {IsoCode? hintIso}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Phone number is empty');
    }

    try {
      final phone = trimmed.startsWith('+')
          ? PhoneNumber.parse(trimmed)
          : PhoneNumber.parse(
              trimmed,
              destinationCountry: hintIso ?? IsoCode.US,
            );
      return ParsedPhone(
        e164: phone.international.replaceAll(' ', ''),
        nationalDigits: phone.nsn,
        formattedNational: phone.formatNsn(),
        dialCode: '+${phone.countryCode}',
        isoCode: phone.isoCode,
      );
    } catch (_) {
      final digits = digitsOnly(trimmed);
      final iso = hintIso ?? IsoCode.US;
      final phone = PhoneNumber.parse(digits, destinationCountry: iso);
      return ParsedPhone(
        e164: phone.international.replaceAll(' ', ''),
        nationalDigits: phone.nsn,
        formattedNational: phone.formatNsn(),
        dialCode: '+${phone.countryCode}',
        isoCode: phone.isoCode,
      );
    }
  }

  static String formatForDisplay(String raw, {IsoCode? hintIso}) {
    try {
      return parseInternational(raw, hintIso: hintIso).formattedNational;
    } catch (_) {
      return raw;
    }
  }

  static String formatInternationalDisplay(String raw, {IsoCode? hintIso}) {
    try {
      final parsed = parseInternational(raw, hintIso: hintIso);
      return parsed.e164.startsWith('+') ? parsed.e164 : '+${parsed.e164}';
    } catch (_) {
      return raw;
    }
  }
}
