import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/cache/isolate_json.dart';
import 'package:lgbtindernew/features/matching/data/models/match.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeJsonMapIsolate', () {
    test('decodes small objects on the caller isolate', () async {
      final map = await decodeJsonMapIsolate('{"ok":true,"n":1}');
      expect(map['ok'], isTrue);
      expect(map['n'], 1);
    });

    test('decodes large objects via compute', () async {
      final payload = '{"bio":"${'x' * (kIsolateJsonMinChars + 8)}"}';
      final map = await decodeJsonMapIsolate(payload);
      expect(map['bio'], hasLength(kIsolateJsonMinChars + 8));
    });
  });

  group('UserProfile equality', () {
    UserProfile profile({String bio = 'hi', bool online = false}) {
      return UserProfile(
        id: 7,
        firstName: 'Alex',
        lastName: 'Lee',
        email: 'alex@example.com',
        profileBio: bio,
        isOnline: online,
      );
    }

    test('same fields are equal without toJson string compare', () {
      expect(profile(), profile());
    });

    test('bio or online changes are not equal', () {
      expect(profile(bio: 'a'), isNot(profile(bio: 'b')));
      expect(profile(online: true), isNot(profile()));
    });
  });

  group('Match equality', () {
    Match match({String name = 'Sam', int unread = 0}) {
      return Match(
        id: 3,
        userId: 9,
        firstName: name,
        matchedAt: DateTime.utc(2026, 9, 12),
        unreadCount: unread,
      );
    }

    test('same fields are equal', () {
      expect(match(), match());
    });

    test('unread changes are not equal', () {
      expect(match(unread: 1), isNot(match()));
    });
  });
}
