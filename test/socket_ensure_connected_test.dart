import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/socket/socket_config.dart';
import 'package:turathy/src/core/helper/socket/socket_ensure.dart';

void main() {
  group('SocketConfig', () {
    test('prefers websocket then polling', () {
      expect(
        SocketConfig.options['transports'],
        ['websocket', 'polling'],
      );
    });

    test('engine reconnection is enabled with a high attempt cap', () {
      expect(SocketConfig.options['reconnection'], isNot(false));
      expect(
        SocketConfig.options['reconnectionAttempts'],
        greaterThanOrEqualTo(20),
      );
    });

    test('points at the production API host', () {
      expect(SocketConfig.baseUrl, 'https://api.alturathaljmeel.com.sa');
    });
  });

  group('ensureSocketConnected', () {
    test('returns immediately when already connected', () async {
      var connectCalls = 0;
      await ensureSocketConnected(
        isConnected: () => true,
        connect: () async {
          connectCalls++;
        },
      );
      expect(connectCalls, 0);
    });

    test('connects then emits when handshake succeeds', () async {
      var connected = false;
      var connectCalls = 0;
      await ensureSocketConnected(
        isConnected: () => connected,
        connect: () async {
          connectCalls++;
          connected = true;
        },
      );
      expect(connectCalls, 1);
    });

    test('rethrows handshake failures without reaching emit', () async {
      var emitReached = false;
      try {
        await ensureSocketConnected(
          isConnected: () => false,
          connect: () async {
            throw Exception('handshake failed');
          },
        );
        emitReached = true;
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('handshake failed'));
      }
      expect(emitReached, isFalse);
    });

    test('throws SocketOfflineException when connect does not connect', () async {
      await expectLater(
        ensureSocketConnected(
          isConnected: () => false,
          connect: () async {},
        ),
        throwsA(isA<SocketOfflineException>()),
      );
    });
  });
}
