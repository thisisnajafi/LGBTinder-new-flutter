import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/settings/data/models/sound_preferences.dart';

void main() {
  group('SoundPreferences', () {
    test('fromJson uses defaults for missing keys', () {
      final prefs = SoundPreferences.fromJson({});

      expect(prefs.messageSound, 'message_default');
      expect(prefs.callRingtone, 'ringtone_default');
      expect(prefs.notificationSound, 'message_default');
      expect(prefs.vibrationEnabled, isTrue);
    });

    test('toJson round-trip', () {
      const prefs = SoundPreferences(
        messageSound: 'message_chime',
        callRingtone: 'ringtone_pride',
        notificationSound: 'message_soft',
        vibrationEnabled: false,
      );

      final restored = SoundPreferences.fromJson(prefs.toJson());

      expect(restored.messageSound, 'message_chime');
      expect(restored.callRingtone, 'ringtone_pride');
      expect(restored.notificationSound, 'message_soft');
      expect(restored.vibrationEnabled, isFalse);
    });
  });

  group('SoundCatalog', () {
    test('findMessageSound returns matching asset', () {
      const catalog = SoundCatalog(
        messageSounds: [
          SoundOption(
            id: 'message_pop',
            name: 'Pop',
            asset: 'assets/sounds/message_pop.wav',
            androidRaw: 'message_pop',
          ),
        ],
        callRingtones: [],
        notificationSounds: [],
      );

      final option = catalog.findMessageSound('message_pop');
      expect(option?.asset, 'assets/sounds/message_pop.wav');
    });
  });
}
