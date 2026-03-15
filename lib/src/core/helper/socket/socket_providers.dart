/// Unified riverpod providers for socket connection, state, and events.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

import 'socket_connection_state.dart';
import 'socket_models.dart';
import 'socket_service.dart';

/// Global socket service provider
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();

  // Auto-dispose when no longer needed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Socket connection status provider
final socketConnectionProvider =
    StreamProvider.autoDispose<SocketConnectionStatus>((ref) {
      final service = ref.watch(socketServiceProvider);
      return service.connectionStream;
    });

/// Helper provider to ensure socket is connected
final socketEnsureConnectedProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final service = ref.watch(socketServiceProvider);
  if (!service.isConnected) {
    await service.connect();
  }
});

// ========== Event Stream Providers ==========

/// Auction started event stream
final auctionStartedProvider = StreamProvider.autoDispose<AuctionModel>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionModel>(
    'auctionStarted',
    (data) => AuctionModel.fromJson(data as Map<String, dynamic>),
  );
});

/// Auction pre-started event stream
final auctionPreStartedProvider = StreamProvider.autoDispose<AuctionModel>((
  ref,
) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionModel>(
    'auctionPreStarted',
    (data) => AuctionModel.fromJson(data as Map<String, dynamic>),
  );
});

/// User count update event stream
final userCountUpdateProvider = StreamProvider.autoDispose<UserCountUpdate>((
  ref,
) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<UserCountUpdate>(
    'userCountUpdate',
    (data) => UserCountUpdate.fromJson(data as Map<String, dynamic>),
  );
});

/// New comment event stream
final newCommentProvider = StreamProvider.autoDispose<CommentEvent>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<CommentEvent>(
    'newComment',
    (data) => CommentEvent.fromJson(data as Map<String, dynamic>),
  );
});

/// State provider to track current bid value
final currentBidStateProvider = StateProvider.autoDispose<AuctionBid?>((ref) {
  final bidEvent = ref.watch(newBidEventProvider);
  return bidEvent.valueOrNull?.newBid;
});

/// State provider to track the latest expiry date from incoming bids
final latestExpiryDateStateProvider = StateProvider.autoDispose<DateTime?>((
  ref,
) {
  final bidEvent = ref.watch(newBidEventProvider);
  return bidEvent.valueOrNull?.expiryDate;
});

/// New bid event stream - now updates the state provider
final newBidEventProvider = StreamProvider.autoDispose<BidPlacedEvent>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<BidPlacedEvent>('newBid', (data) {
    return BidPlacedEvent.fromJson(data as Map<String, dynamic>);
  });
});

/// Helper method to reset the new bid stream
void resetNewBidStream(WidgetRef ref) {
  // Reset the state provider to null immediately
  ref.read(currentBidStateProvider.notifier).state = null;
  ref.read(latestExpiryDateStateProvider.notifier).state = null;
}

/// Notifier that accumulates ALL incoming socket bids (newest first)
class AccumulatedBidsNotifier extends StateNotifier<List<AuctionBid>> {
  AccumulatedBidsNotifier() : super([]);

  /// Replace the entire bid list with the authoritative list from the backend
  void updateAll(List<AuctionBid> bids) {
    state = bids;
  }

  void addBid(AuctionBid bid) {
    // Avoid duplicates by checking bid id
    if (bid.id != null && state.any((b) => b.id == bid.id)) return;
    state = [bid, ...state];
  }
}

/// Provider that accumulates every real-time socket bid into a list
final accumulatedBidsProvider =
    StateNotifierProvider.autoDispose<
      AccumulatedBidsNotifier,
      List<AuctionBid>
    >((ref) {
      final notifier = AccumulatedBidsNotifier();
      // Listen to new bid events and use the full authoritative list from backend
      ref.listen<AsyncValue<BidPlacedEvent>>(newBidEventProvider, (
        previous,
        next,
      ) {
        final event = next.valueOrNull;
        if (event != null) {
          // Use the full auctionBids list from the backend as the source of truth
          if (event.auctionBids.isNotEmpty) {
            notifier.updateAll(event.auctionBids);
          } else {
            // Fallback: if auctionBids is empty, just add the new bid
            notifier.addBid(event.newBid);
          }
        }
      });
      return notifier;
    });

/// Auction canceled event stream
final auctionCanceledProvider = StreamProvider.autoDispose<AuctionModel>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionModel>(
    'auctionCanceled',
    (data) => AuctionModel.fromJson(data as Map<String, dynamic>),
  );
});

/// Auction ended event stream
final auctionEndedProvider = StreamProvider.autoDispose<AuctionEndedEvent>((
  ref,
) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionEndedEvent>(
    'auctionEnded',
    (data) => AuctionEndedEvent.fromJson(data as Map<String, dynamic>),
  );
});

/// Auction item ended event stream
final auctionItemEndedProvider =
    StreamProvider.autoDispose<AuctionItemEndedEvent>((ref) {
      final service = ref.watch(socketServiceProvider);
      return service.getEventStream<AuctionItemEndedEvent>(
        'auctionItemEnded',
        (data) => AuctionItemEndedEvent.fromJson(data as Map<String, dynamic>),
      );
    });

/// Auction product change event stream
final auctionProductChangeProvider =
    StateProvider.autoDispose<AuctionProductChangeEvent?>((ref) {
      final productChange = ref.watch(_auctionProductChangeProvider);
      return productChange.valueOrNull;
    });

/// Auction product change event stream
final _auctionProductChangeProvider =
    StreamProvider.autoDispose<AuctionProductChangeEvent>((ref) {
      final service = ref.watch(socketServiceProvider);
      return service.getEventStream<AuctionProductChangeEvent>(
        'auction_change_product',
        (data) =>
            AuctionProductChangeEvent.fromJson(data as Map<String, dynamic>),
      );
    });

void resetProductChangeStream(WidgetRef ref) {
  ref.read(auctionProductChangeProvider.notifier).state = null;
}

/// Socket error event stream
final socketErrorProvider = StreamProvider.autoDispose<SocketErrorEvent>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<SocketErrorEvent>(
    'error',
    (data) => SocketErrorEvent.fromJson(data as Map<String, dynamic>),
  );
});

/// Bid rejected event stream — emitted when the server rejects a bid due to
/// a stale price. The event includes the server's current price so the UI
/// can self-correct instantly without an HTTP request.
final bidRejectedProvider = StreamProvider.autoDispose<BidRejectedEvent>((
  ref,
) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<BidRejectedEvent>(
    'bidRejected',
    (data) => BidRejectedEvent.fromJson(data as Map<String, dynamic>),
  );
});

/// Auction sync event stream — emitted by the server when a client (re-)joins
/// a room or requests a manual sync. Carries the authoritative `seq` counter
/// so the client can bootstrap its rolling counter.
final auctionSyncProvider = StreamProvider.autoDispose<AuctionModel>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionModel>(
    'auctionSync',
    (data) {
      final json = data as Map<String, dynamic>;
      // Seed the rolling counter whenever we receive a fresh snapshot.
      final seqFromServer = json['seq'] as int?;
      if (seqFromServer != null) {
        // Schedule a microtask so we don't mutate state during a build.
        Future.microtask(() {
          try {
            ref.read(auctionSeqProvider.notifier).state = seqFromServer;
          } catch (_) {}
        });
      }
      return AuctionModel.fromJson(json);
    },
  );
});

// ── Rolling sequence counter ──────────────────────────────────────────────────

/// Stores the last successfully processed `seq` value from the server.
/// Initialised to -1 ("not yet bootstrapped").
/// Reset to whatever `seq` arrives in `auctionSync` to survive server restarts.
final auctionSeqProvider = StateProvider<int>((ref) => -1);

/// Side-effect provider: watches all sequenced events, detects forward gaps,
/// and calls `requestSync` when a gap is found — no UI state is changed here.
/// Screens should call `ref.watch(auctionGapDetectedProvider)` to activate it.
final auctionGapDetectedProvider = Provider<void>((ref) {
  // We must watch inside a provider body so Riverpod re-evaluates when events
  // arrive. We use a helper closure to avoid code duplication.
  void checkSeq(int? incoming, int auctionId) {
    if (incoming == null) return; // event has no seq yet (pre-deploy compat)
    final last = ref.read(auctionSeqProvider);

    if (last == -1) {
      // First event: bootstrap counter silently.
      ref.read(auctionSeqProvider.notifier).state = incoming;
      return;
    }

    if (incoming <= last) {
      // Duplicate or retransmit — ignore safely.
      return;
    }

    if (incoming > last + 1) {
      // Gap detected! Ask the server for a fresh snapshot.
      // ignore: avoid_print
      assert(() {
        // ignore: avoid_print
        print('[SeqGap] auction=$auctionId gap=${incoming - last - 1} '  
              '(last=$last, received=$incoming) — requesting sync');
        return true;
      }());
      try {
        ref.read(socketActionsProvider).requestSync(auctionId);
      } catch (_) {}
    }

    // Advance the counter regardless (fill in the gap optimistically).
    ref.read(auctionSeqProvider.notifier).state = incoming;
  }

  // Listen to newBid events.
  ref.listen<AsyncValue<BidPlacedEvent>>(newBidEventProvider, (_, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    // Derive auctionId from the bid itself (available on AuctionBid).
    checkSeq(event.seq, event.newBid.auctionId ?? 0);
  });

  // Listen to auctionItemEnded events.
  ref.listen<AsyncValue<AuctionItemEndedEvent>>(auctionItemEndedProvider, (_, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    checkSeq(event.seq, event.auction.id ?? 0);
  });

  // Listen to auctionEnded events.
  ref.listen<AsyncValue<AuctionEndedEvent>>(auctionEndedProvider, (_, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    checkSeq(event.seq, event.auctionId);
  });
});

// ─────────────────────────────────────────────────────────────────────────────

/// Provider for socket actions (emit events)
final socketActionsProvider = Provider.autoDispose<SocketActions>((ref) {
  final service = ref.watch(socketServiceProvider);
  return SocketActions._(service);
});

// ── State Broadcast Provider ───────────────────────────────────────────────────

/// Stream of `auctionStateUpdate` events blindly fired by the server every 2s.
/// Contains the most up-to-date timer and the latest 3 bids for the active product.
final auctionStateUpdateProvider =
    StreamProvider.autoDispose<AuctionStateUpdateEvent>((ref) {
      final service = ref.watch(socketServiceProvider);
      return service.getEventStream<AuctionStateUpdateEvent>(
        'auctionStateUpdate',
        (data) =>
            AuctionStateUpdateEvent.fromJson(data as Map<String, dynamic>),
      );
    });

// ─────────────────────────────────────────────────────────────────────────────

/// Socket actions class for emitting events
class SocketActions {
  final SocketService _service;

  const SocketActions._(this._service);

  /// Start live auction
  Future<void> startLiveAuction(int auctionId, int userId) async {
    await _ensureConnected();
    _service.emitStartLiveAuction(auctionId, userId);
  }

  /// Join auction
  Future<void> joinAuction(int auctionId, int userId) async {
    await _ensureConnected();
    _service.emitJoinAuction(auctionId, userId);
  }

  /// Leave auction
  Future<void> leaveAuction(int auctionId, int userId) async {
    await _ensureConnected();
    _service.emitLeaveAuction(auctionId, userId);
  }

  /// Send comment
  Future<void> sendComment(int auctionId, int userId, String comment) async {
    await _ensureConnected();
    _service.emitComment(auctionId, userId, comment);
  }

  /// Place bid
  Future<void> placeBid(
    int auctionId,
    int userId,
    double amount,
    int productId,
  ) async {
    await _ensureConnected();
    _service.emitPlaceBid(auctionId, userId, amount, productId);
  }

  /// Cancel auction
  Future<void> cancelAuction(int auctionId, int userId) async {
    await _ensureConnected();
    _service.emitCancelAuction(auctionId, userId);
  }

  /// Award auction
  Future<void> awardAuction(int auctionId, int userId, String product) async {
    await _ensureConnected();
    _service.emitAwardingAuction(auctionId, userId, product);
  }

  /// Change current product
  Future<void> changeCurrentProduct({
    required int auctionId,
    required String product,
    required double minBidPrice,
    required double bidPrice,
    required double actualPrice,
  }) async {
    await _ensureConnected();
    _service.emitChangeCurrentProduct(
      auctionId: auctionId,
      product: product,
      minBidPrice: minBidPrice,
      bidPrice: bidPrice,
      actualPrice: actualPrice,
    );
  }

  /// Request a fresh auction state snapshot (gap recovery)
  Future<void> requestSync(int auctionId) async {
    await _ensureConnected();
    _service.emitRequestSync(auctionId);
  }

  /// Ensure socket is connected before performing actions
  Future<void> _ensureConnected() async {
    if (!_service.isConnected) {
      await _service.connect();
    }
  }
}
