import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../../features/reference_data/data/models/reference_item.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/country_phone_utils.dart';
import 'national_phone_input_formatter.dart';

/// Country-aware phone row: read-only dial code + formatted national number field.
class CountryPhoneInput extends StatefulWidget {
  final ReferenceItem? country;
  final TextEditingController nationalController;
  final bool required;
  final bool dialCodeEditable;
  final TextEditingController? dialCodeController;
  final ValueChanged<ParsedPhone?>? onPhoneChanged;
  final String? Function(String?)? validator;

  const CountryPhoneInput({
    super.key,
    required this.nationalController,
    this.country,
    this.required = true,
    this.dialCodeEditable = false,
    this.dialCodeController,
    this.onPhoneChanged,
    this.validator,
  });

  @override
  State<CountryPhoneInput> createState() => _CountryPhoneInputState();
}

class _CountryPhoneInputState extends State<CountryPhoneInput> {
  IsoCode? _lastIso;

  @override
  void didUpdateWidget(covariant CountryPhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIso = CountryPhoneUtils.resolveIso(
      country: oldWidget.country,
      dialCode: widget.dialCodeController?.text,
    );
    final newIso = _iso;
    if (oldIso != newIso) {
      _syncDialCodeController(newIso);
      _reformatNational(newIso);
    }
  }

  IsoCode get _iso => CountryPhoneUtils.resolveIso(
        country: widget.country,
        dialCode: widget.dialCodeController?.text,
      );

  String get _dialCode => CountryPhoneUtils.dialCodeForCountry(widget.country);

  void _syncDialCodeController(IsoCode iso) {
    final controller = widget.dialCodeController;
    if (controller == null) return;
    final dial = CountryPhoneUtils.dialCodeForCountry(
      widget.country,
      fallback: '+${PhoneNumber.parse('1', destinationCountry: iso).countryCode}',
    );
    if (controller.text != dial) {
      controller.text = dial;
    }
  }

  void _reformatNational(IsoCode iso) {
    final digits = CountryPhoneUtils.digitsOnly(widget.nationalController.text);
    if (digits.isEmpty) return;
    final formatted = CountryPhoneUtils.formatPartial(digits, iso);
    if (widget.nationalController.text != formatted) {
      widget.nationalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _emitChange(iso);
  }

  void _emitChange(IsoCode iso) {
    final parsed = CountryPhoneUtils.tryBuildFromNational(
      nationalInput: widget.nationalController.text,
      iso: iso,
      dialCode: _dialCode,
    );
    widget.onPhoneChanged?.call(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final iso = _iso;
    if (_lastIso != iso) {
      _lastIso = iso;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncDialCodeController(iso);
      });
    }

    final hint = CountryPhoneUtils.exampleNationalHint(iso);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: widget.dialCodeEditable && widget.dialCodeController != null
              ? TextFormField(
                  controller: widget.dialCodeController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                  ),
                  validator: CountryPhoneUtils.validateDialCode,
                  onChanged: (_) {
                    setState(() {});
                    _emitChange(_iso);
                  },
                )
              : InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Code',
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.35),
                  ),
                  child: Text(
                    widget.dialCodeController?.text.isNotEmpty == true
                        ? widget.dialCodeController!.text
                        : _dialCode,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.spacingSM),
        Expanded(
          child: TextFormField(
            controller: widget.nationalController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: hint,
            ),
            inputFormatters: [
              NationalPhoneInputFormatter(iso),
            ],
            validator: widget.validator ??
                (value) => CountryPhoneUtils.validateNational(
                      value,
                      iso,
                      required: widget.required,
                    ),
            onChanged: (_) => _emitChange(iso),
          ),
        ),
      ],
    );
  }
}

/// Standalone international phone field with optional country selector above it.
class InternationalPhoneFormField extends StatelessWidget {
  final ReferenceItem? country;
  final TextEditingController controller;
  final TextEditingController? dialCodeController;
  final bool required;
  final ValueChanged<ParsedPhone?>? onPhoneChanged;

  const InternationalPhoneFormField({
    super.key,
    required this.controller,
    this.country,
    this.dialCodeController,
    this.required = true,
    this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CountryPhoneInput(
      country: country,
      nationalController: controller,
      dialCodeController: dialCodeController,
      required: required,
      onPhoneChanged: onPhoneChanged,
    );
  }
}
