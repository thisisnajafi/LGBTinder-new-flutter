import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../utils/country_phone_utils.dart';

/// Formats national phone numbers as the user types, based on [isoCode].
class NationalPhoneInputFormatter extends TextInputFormatter {
  final IsoCode isoCode;

  NationalPhoneInputFormatter(this.isoCode);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text == oldValue.text) return newValue;

    final oldDigits = CountryPhoneUtils.digitsOnly(oldValue.text);
    var newDigits = CountryPhoneUtils.digitsOnly(newValue.text);

    if (newDigits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final maxLen = CountryPhoneUtils.maxNationalDigits(isoCode);
    if (newDigits.length > maxLen) {
      newDigits = newDigits.substring(0, maxLen);
    }

    // Allow deletion without forcing cursor to end when removing formatting chars.
    if (newDigits.length < oldDigits.length) {
      final formatted = CountryPhoneUtils.formatPartial(newDigits, isoCode);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    final formatted = CountryPhoneUtils.formatPartial(newDigits, isoCode);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
