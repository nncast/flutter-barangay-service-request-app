import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barangay_app/core/models.dart';
import 'package:barangay_app/core/ui_helpers.dart';

void main() {
  group('UserModel.initials', () {
    UserModel user(String name) => UserModel(id: 1, name: name, email: 'a@b.c', role: 'resident');

    test('uses first and last name', () => expect(user('Maria Clara Santos').initials, 'MS'));
    test('ignores repeated spaces', () => expect(user('Juan  dela   Cruz').initials, 'JC'));
    test('handles a single name', () => expect(user('maria').initials, 'M'));
    test('handles an empty name', () => expect(user('  ').initials, 'U'));
  });

  group('RequestModel.fromJson', () {
    final json = {
      'id': '7',
      'tracking_code': 'BSR-2026-00007',
      'title': 'Clearance',
      'description': 'For work',
      'status': 'in_review',
      'created_at': '2026-10-04T06:00:00.000000Z',
      'logs': [
        {'id': 1, 'old_status': null, 'new_status': 'pending', 'created_at': '2026-10-04T06:00:00.000000Z'},
        {'id': 2, 'old_status': 'pending', 'new_status': 'in_review', 'created_at': '2026-10-04T07:00:00.000000Z'},
      ],
    };

    test('parses ids given as strings and a null first old_status', () {
      final request = RequestModel.fromJson(json);
      expect(request.id, 7);
      expect(request.logs.last.oldStatus, isNull);
    });

    test('lists history newest first', () {
      expect(RequestModel.fromJson(json).logs.first.newStatus, 'in_review');
    });

    test('only pending requests can be cancelled', () {
      expect(RequestModel.fromJson(json).canCancel, isFalse);
      expect(RequestModel.fromJson({...json, 'status': 'pending'}).canCancel, isTrue);
    });

    test('cancelled requests cannot be updated by staff', () {
      expect(RequestModel.fromJson({...json, 'status': 'cancelled'}).canUpdateStatus, isFalse);
    });
  });

  group('status helpers', () {
    test('labels are human readable', () {
      expect(statusLabel('in_review'), 'In Review');
      expect(statusLabel('cancelled'), 'Cancelled');
      expect(statusLabel(''), 'Unknown');
      expect(statusLabel(null), 'Unknown');
    });

    test('every status has its own color', () {
      final colors = kStaffSettableStatuses.map(statusColor).toSet();
      expect(colors.length, kStaffSettableStatuses.length);
    });

    test('labels on light colors are black, on dark colors white', () {
      expect(onColor(statusColor('pending')), kCharcoal);
      expect(onColor(statusColor('approved')), kCharcoal);
      expect(onColor(statusColor('completed')), kWhite);
      expect(onColor(statusColor('rejected')), kWhite);
    });

    test('dates are shown in local time', () {
      final utc = DateTime.utc(2026, 10, 4, 6, 5);
      final local = utc.toLocal();
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      expect(formatDateTime(utc.toIso8601String()), contains('$hour:05'));
    });
  });

  group('WCAG AA contrast', () {
    Matcher atLeast(double ratio) => greaterThanOrEqualTo(ratio);

    test('every status, priority and role tag is readable (4.5:1)', () {
      final fills = [
        ...kRequestStatuses.map(statusColor),
        ...['low', 'normal', 'high', 'urgent'].map(priorityColor),
        kCharcoal, kOrange, kYellow, kLine, kMuted, // roles and "You"
      ];
      for (final fill in fills) {
        expect(contrastRatio(fill, onColor(fill)), atLeast(4.5), reason: '$fill');
      }
    });

    test('body and secondary text on every background (4.5:1)', () {
      for (final bg in [kWhite, kSurface, kYellowSoft]) {
        expect(contrastRatio(kCharcoal, bg), atLeast(4.5));
        expect(contrastRatio(kGray, bg), atLeast(4.5));
      }
      expect(contrastRatio(kRed, kWhite), atLeast(4.5)); // Reject, Delete, required *
      expect(contrastRatio(kCharcoal, kOrange), atLeast(4.5)); // button labels
      expect(contrastRatio(kYellow, kCharcoal), atLeast(4.5)); // hero card counts
      expect(contrastRatio(Color.alphaBlend(kWhite.withValues(alpha: 0.6), kCharcoal), kCharcoal), atLeast(4.5)); // hero labels
    });

    test('field outlines and state indicators (3:1)', () {
      for (final bg in [kWhite, kSurface]) {
        expect(contrastRatio(kOutline, bg), atLeast(3));
        expect(contrastRatio(kOrangeDark, bg), atLeast(3)); // unread dot, spinner
      }
    });
  });

  test('notification is_read accepts 0/1 and booleans', () {
    NotificationModel n(dynamic isRead) =>
        NotificationModel.fromJson({'id': 1, 'title': 't', 'body': 'b', 'is_read': isRead, 'created_at': ''});
    expect(n(1).isRead, isTrue);
    expect(n(false).isRead, isFalse);
    expect(n(0).markedRead().isRead, isTrue);
  });
}
