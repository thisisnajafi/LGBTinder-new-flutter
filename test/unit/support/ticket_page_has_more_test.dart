import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/screens/support_tickets_screen.dart';

void main() {
  test('uses has_more when pagination is present', () {
    expect(
      ticketPageHasMore(
        {
          'pagination': {'has_more': true},
        },
        1,
        3,
      ),
      isTrue,
    );
    expect(
      ticketPageHasMore(
        {
          'meta': {'hasMore': false},
        },
        1,
        15,
      ),
      isFalse,
    );
  });

  test('compares page against last_page', () {
    expect(
      ticketPageHasMore(
        {
          'tickets': {'last_page': 3},
        },
        2,
        15,
      ),
      isTrue,
    );
    expect(
      ticketPageHasMore(
        {
          'tickets': {'lastPage': 2},
        },
        2,
        15,
      ),
      isFalse,
    );
  });

  test('falls back to a full page of items', () {
    expect(ticketPageHasMore({}, 1, 15), isTrue);
    expect(ticketPageHasMore({}, 1, 4), isFalse);
  });
}
