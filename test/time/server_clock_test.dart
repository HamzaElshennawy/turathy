import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/time/server_clock.dart';

void main() {
  test('drops a round trip over 1500ms and keeps the median', () {
    expect(sampleOffset(t0: 0, t1: 1600, serverNow: 1000), isNull);
    final sample = sampleOffset(t0: 0, t1: 100, serverNow: 1000);
    expect(sample?.offset, 950);
    expect(
      medianOffset([10, 12, 11, 1000, 9]),
      11,
    );
  });

  test('skewed device clocks show the same remaining time', () {
    const expiresAt = 100000;
    final ahead = serverNowMs(90000, -5000);
    final behind = serverNowMs(80000, 5000);
    expect(remainingMs(expiresAt, ahead), 15000);
    expect(remainingMs(expiresAt, behind), 15000);
  });

  test('clamps at zero and rounds the display up', () {
    expect(remainingMs(1000, 1500), 0);
    expect(displaySeconds(0), 0);
    expect(displaySeconds(1), 1);
    expect(displaySeconds(1000), 1);
    expect(displaySeconds(1001), 2);
    expect(formatClockDuration(1001), '2 ث');
    expect(formatClockDuration(1000), '1 ث');
    expect(nextTickDelay(2500), 505);
    expect(nextTickDelay(0), 1000);
  });

  test('passive estimate yields to a measured round trip', () {
    final clock = ServerClock();
    clock.notePassive(10000, 8000);
    expect(clock.offset(), 2000);
    clock.record(sampleOffset(t0: 0, t1: 40, serverNow: 50));
    expect(clock.offset(), 30);
    clock.notePassive(99000, 1);
    expect(clock.offset(), 30);
  });

  test('gate drops stale events, syncs on a gap, and resets on a new epoch', () {
    Map<String, dynamic> event(int seq, int epoch, {bool snapshot = false}) => {
      'clock': {
        'serverNow': 1000,
        'expiresAt': 5000,
        'lotId': 9,
        'lot_number': '4',
        'seq': seq,
        'epoch': epoch,
        'snapshot': snapshot,
      },
    };

    final first = gateServerEvent(GateState.initial, event(1, 100));
    expect(first.accept, isTrue);
    final stale = gateServerEvent(first.next, event(1, 100));
    expect(stale.accept, isFalse);
    final gap = gateServerEvent(first.next, event(3, 100));
    expect(gap.sync, isTrue);
    expect(gap.next.lastSeq, 3);

    final high = gateServerEvent(GateState.initial, event(10, 100));
    final restarted = gateServerEvent(high.next, event(1, 200));
    expect(restarted.accept, isTrue);
    expect(restarted.next.epoch, 200);
    expect(restarted.next.lastSeq, 1);

    final current = gateServerEvent(high.next, event(10, 100, snapshot: true));
    expect(current.accept, isTrue);
    expect(gateServerEvent(high.next, event(9, 100, snapshot: true)).accept, isFalse);
  });

  test('room gate drops a repeated delta and still accepts the snapshot', () {
    final gate = RoomGate();
    Map<String, dynamic> event(int seq, {bool snapshot = false}) => {
      'clock': {
        'serverNow': 1000,
        'expiresAt': 5000,
        'lotId': 9,
        'lot_number': '4',
        'seq': seq,
        'epoch': 100,
        'snapshot': snapshot,
      },
    };
    expect(gate.consider(event(2)).accept, isTrue);
    expect(gate.consider(event(2)).accept, isFalse);
    expect(gate.consider(event(2, snapshot: true)).accept, isTrue);
    expect(gate.consider(event(4)).sync, isTrue);
  });

  test('resync triggers inside one second collapse', () {
    expect(shouldResync(null, 1000), isTrue);
    expect(shouldResync(1000, 1500), isFalse);
    expect(shouldResync(1000, 2000), isTrue);
  });
}
