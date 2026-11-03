const int maxRttMs = 1500;
const int clockSampleLimit = 5;
const String lotClosingLabel = 'جاري إغلاق البند...';

class ClockSample {
  const ClockSample({required this.offset, required this.rtt, required this.at});

  final double offset;
  final int rtt;
  final int at;
}

class ClockStamp {
  const ClockStamp({
    required this.serverNow,
    required this.expiresAt,
    required this.lotId,
    required this.lotNumber,
    required this.seq,
    required this.epoch,
    required this.snapshot,
  });

  final int serverNow;
  final int? expiresAt;
  final int? lotId;
  final String? lotNumber;
  final int seq;
  final int epoch;
  final bool snapshot;

  static ClockStamp? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final seq = raw['seq'];
    final epoch = raw['epoch'];
    if (seq is! num || epoch is! num) return null;
    final serverNow = raw['serverNow'];
    final expiresAt = raw['expiresAt'];
    final lotId = raw['lotId'];
    final lotNumber = raw['lot_number'];
    return ClockStamp(
      serverNow: serverNow is num ? serverNow.toInt() : 0,
      expiresAt: expiresAt is num ? expiresAt.toInt() : null,
      lotId: lotId is num ? lotId.toInt() : null,
      lotNumber: lotNumber == null || '$lotNumber'.isEmpty ? null : '$lotNumber',
      seq: seq.toInt(),
      epoch: epoch.toInt(),
      snapshot: raw['snapshot'] == true,
    );
  }
}

class GateState {
  const GateState({required this.epoch, required this.lastSeq, required this.legacySeq});

  final int? epoch;
  final int lastSeq;
  final int legacySeq;

  static const initial = GateState(epoch: null, lastSeq: -1, legacySeq: 0);
}

class GateResult {
  const GateResult({
    required this.accept,
    required this.sync,
    required this.next,
    required this.serverNow,
    required this.expiresAt,
  });

  final bool accept;
  final bool sync;
  final GateState next;
  final int? serverNow;
  final int? expiresAt;
}

ClockSample? sampleOffset({required int t0, required int t1, required int serverNow}) {
  final rtt = t1 - t0;
  if (rtt < 0 || rtt > maxRttMs) return null;
  return ClockSample(offset: serverNow + rtt / 2 - t1, rtt: rtt, at: t1);
}

double medianOffset(List<double> offsets) {
  if (offsets.isEmpty) return 0;
  final sorted = [...offsets]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

int serverNowMs(int clientNow, double offset) => clientNow + offset.round();

int remainingMs(int? expiresAt, int now) {
  if (expiresAt == null) return 0;
  final left = expiresAt - now;
  return left < 0 ? 0 : left;
}

int displaySeconds(int remainMs) {
  if (remainMs <= 0) return 0;
  return (remainMs / 1000).ceil();
}

String formatClockDuration(int remainMs) {
  final total = displaySeconds(remainMs);
  if (total <= 0) return '0 sec';
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  if (hours > 0) return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  if (minutes > 0) return '${two(minutes)}:${two(seconds)}';
  return '$seconds sec';
}

int nextTickDelay(int remainMs) {
  if (remainMs <= 0) return 1000;
  return (remainMs % 1000) + 5;
}

bool shouldResync(int? lastAt, int now, {int minGapMs = 1000}) {
  if (lastAt == null) return true;
  return now - lastAt >= minGapMs;
}

class ServerClock {
  final List<ClockSample> _samples = [];

  double offset() => medianOffset(_samples.map((sample) => sample.offset).toList());

  int nowMs([int? clientNow]) => serverNowMs(clientNow ?? DateTime.now().millisecondsSinceEpoch, offset());

  DateTime nowDate([DateTime? clientNow]) {
    final base = clientNow ?? DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(serverNowMs(base.millisecondsSinceEpoch, offset()));
  }

  void record(ClockSample? sample) {
    if (sample == null) return;
    final measured = _samples.where((row) => row.rtt > 0).toList();
    measured.add(sample);
    _samples
      ..clear()
      ..addAll(measured.length > clockSampleLimit ? measured.sublist(measured.length - clockSampleLimit) : measured);
  }

  void notePassive(int serverNow, int receivedAt) {
    if (_samples.any((sample) => sample.rtt > 0)) return;
    _samples
      ..clear()
      ..add(ClockSample(offset: (serverNow - receivedAt).toDouble(), rtt: 0, at: receivedAt));
  }
}

final ServerClock serverClock = ServerClock();

/// One gate for the open live room. Snapshots may repeat the current seq.
class RoomGate {
  GateState state = GateState.initial;

  GateResult consider(Map<String, dynamic> event) {
    final result = gateServerEvent(state, event);
    state = result.next;
    final serverNow = result.serverNow;
    if (result.accept && serverNow != null) {
      serverClock.notePassive(serverNow, DateTime.now().millisecondsSinceEpoch);
    }
    return result;
  }

  void reset() {
    state = GateState.initial;
  }
}

final RoomGate roomGate = RoomGate();

GateResult gateServerEvent(GateState state, Map<String, dynamic> event) {
  final clock = ClockStamp.tryParse(event['clock']);
  if (clock == null) return _legacyGate(state, event);
  if (state.epoch != clock.epoch) {
    return _taken(
      clock,
      false,
      GateState(epoch: clock.epoch, lastSeq: clock.seq, legacySeq: state.legacySeq),
    );
  }
  if (clock.snapshot) {
    if (clock.seq < state.lastSeq) return _dropped(state);
    return _taken(
      clock,
      false,
      GateState(epoch: clock.epoch, lastSeq: clock.seq, legacySeq: state.legacySeq),
    );
  }
  if (clock.seq <= state.lastSeq) return _dropped(state);
  return _taken(
    clock,
    clock.seq > state.lastSeq + 1,
    GateState(epoch: clock.epoch, lastSeq: clock.seq, legacySeq: state.legacySeq),
  );
}

DateTime? expiryFromClock(Map<String, dynamic> json) {
  final clock = ClockStamp.tryParse(json['clock']);
  final expiresAt = clock?.expiresAt;
  if (expiresAt == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(expiresAt, isUtc: true).toLocal();
}

GateResult _legacyGate(GateState state, Map<String, dynamic> event) {
  final raw = event['seq'];
  if (raw is! num) {
    return GateResult(accept: true, sync: false, next: state, serverNow: null, expiresAt: null);
  }
  final seq = raw.toInt();
  if (seq <= state.legacySeq) return _dropped(state);
  return GateResult(
    accept: true,
    sync: false,
    next: GateState(epoch: state.epoch, lastSeq: state.lastSeq, legacySeq: seq),
    serverNow: null,
    expiresAt: null,
  );
}

GateResult _dropped(GateState state) {
  return GateResult(accept: false, sync: false, next: state, serverNow: null, expiresAt: null);
}

GateResult _taken(ClockStamp clock, bool sync, GateState next) {
  return GateResult(
    accept: true,
    sync: sync,
    next: next,
    serverNow: clock.serverNow,
    expiresAt: clock.expiresAt,
  );
}
