import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_list_filter.dart';

void main() {
  const rows = [
    {
      'id': 1,
      'name': 'Alex',
      'last_message': 'hey there',
      'unread_count': 2,
      'is_online': false,
    },
    {
      'id': 2,
      'name': 'Sam',
      'last_message': 'Photo',
      'unread_count': 0,
      'is_online': true,
    },
    {
      'id': 3,
      'name': 'Jordan',
      'last_message': 'see you',
      'unread_count': 1,
      'is_online': true,
    },
  ];

  test('unread and search are a single pass', () {
    final result = ChatListFilter.apply(
      source: rows,
      filter: ChatListRowFilter.unread,
      query: 'ALEX',
    );

    expect(result, hasLength(1));
    expect(result.single['id'], 1);
  });

  test('online filter keeps online rows only', () {
    final result = ChatListFilter.apply(
      source: rows,
      filter: ChatListRowFilter.online,
    );

    expect(result.map((row) => row['id']), [2, 3]);
  });

  test('online filter prefers live presence over stale list flags', () {
    final result = ChatListFilter.apply(
      source: rows,
      filter: ChatListRowFilter.online,
      presenceByUser: const {1: true, 2: false, 3: true},
    );

    expect(result.map((row) => row['id']), [1, 3]);
  });

  test('empty query keeps all rows for all filter', () {
    final result = ChatListFilter.apply(
      source: rows,
      filter: ChatListRowFilter.all,
    );

    expect(result, hasLength(3));
  });

  test('search matches first_name last_name and preview without an API', () {
    final byFirst = ChatListFilter.apply(
      source: const [
        {
          'id': 4,
          'name': '',
          'first_name': 'Riley',
          'last_name': 'Chen',
          'last_message': 'ok',
        },
      ],
      filter: ChatListRowFilter.all,
      query: 'ril',
    );
    expect(byFirst.single['id'], 4);

    final byPreview = ChatListFilter.apply(
      source: rows,
      filter: ChatListRowFilter.all,
      query: 'see you',
    );
    expect(byPreview.single['id'], 3);
  });

  test('hidden ids are skipped without an API', () {
    final result = ChatListFilter.apply(
      source: rows,
      filter: ChatListRowFilter.all,
      hiddenIds: {1, 3},
    );

    expect(result.map((row) => row['id']), [2]);
  });

  test('pinned rows stay first after filter and search', () {
    const mixed = [
      {
        'id': 1,
        'name': 'Alex',
        'last_message': 'hey',
        'unread_count': 0,
        'is_pinned': false,
      },
      {
        'id': 2,
        'name': 'Sam',
        'last_message': 'ok',
        'unread_count': 0,
        'is_pinned': true,
      },
      {
        'id': 3,
        'name': 'Jordan',
        'last_message': 'later',
        'unread_count': 0,
        'is_pinned': true,
      },
    ];

    final result = ChatListFilter.apply(
      source: mixed,
      filter: ChatListRowFilter.all,
    );

    expect(result.map((row) => row['id']), [2, 3, 1]);
  });
}
