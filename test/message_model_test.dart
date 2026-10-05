import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hussein_advmobprog/models/message.dart';

// Lab Activity 6 - HusseinAdvmobprogMessage serialization checks.
void main() {
  group('HusseinAdvmobprogMessage', () {
    test('toMap and fromMap keep every field', () {
      final timestamp = Timestamp.fromDate(DateTime(2026, 9, 27, 14, 30));

      final message = HusseinAdvmobprogMessage(
        senderId: 'uid_a',
        senderEmail: 'a@example.com',
        receiverId: 'uid_b',
        message: 'Hello!',
        timestamp: timestamp,
      );

      final restored = HusseinAdvmobprogMessage.fromMap(message.toMap());

      expect(restored.senderId, 'uid_a');
      expect(restored.senderEmail, 'a@example.com');
      expect(restored.receiverId, 'uid_b');
      expect(restored.message, 'Hello!');
      expect(restored.timestamp, timestamp);
      expect(restored.isRead, false);
    });

    test('fromMap falls back safely when fields are missing', () {
      final restored = HusseinAdvmobprogMessage.fromMap(const {});

      expect(restored.senderId, '');
      expect(restored.senderEmail, '');
      expect(restored.receiverId, '');
      expect(restored.message, '');
      expect(restored.timestamp, isA<Timestamp>());
      expect(restored.isRead, true);
    });

    test('fromMap converts DateTime and epoch milliseconds', () {
      final date = DateTime(2026, 1, 2, 3, 4, 5);

      expect(
        HusseinAdvmobprogMessage.fromMap({
          'timestamp': Timestamp.fromDate(date),
        }).timestamp,
        Timestamp.fromDate(date),
      );

      expect(
        HusseinAdvmobprogMessage.fromMap({'timestamp': date}).timestamp,
        Timestamp.fromDate(date),
      );

      expect(
        HusseinAdvmobprogMessage.fromMap({
          'timestamp': date.millisecondsSinceEpoch,
        }).timestamp,
        Timestamp.fromDate(date),
      );
    });

    test('fromMap tolerates a null timestamp', () {
      final restored = HusseinAdvmobprogMessage.fromMap({
        'senderId': 'uid_a',
        'message': 'pending write',
        'timestamp': null,
      });

      expect(restored.message, 'pending write');
      expect(restored.timestamp, isA<Timestamp>());
    });
  });
}
