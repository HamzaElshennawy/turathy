/// {@category Core}
///
/// Riverpod providers and state management for the WebSocket system.
/// 
/// This file bridges the [SocketService] with the rest of the application using 
/// Riverpod, providing:
/// - Reactive access to connection status and event streams.
/// - Authoritative state synchronization logic (gap detection).
/// - A high-level [SocketActions] class for emitting events.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

import 'socket_connection_state.dart';
import 'socket_models.dart';
import 'socket_service.dart';

/// The primary provider for the singleton [SocketService] instance.
/// 
/// Automatically handles resource cleanup via [ref.onDispose] to ensure 
/// connections are closed when the provider is no longer needed.
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Watches the raw connection status of the global socket.
/// 
/// Useful for UI elements that need to show "Connecting...", "Connected", 
/// or "Offline" status indicators.
final socketConnectionProvider =
    StreamProvider.autoDispose<SocketConnectionStatus>((ref) {
      final service = ref.watch(socketServiceProvider);
      return service.connectionStream;
    });

/// A utility provider that attempts to connect the socket if not already active.
/// 
/// Consumers can 'read' or 'watch' this to trigger the initial connection handshake.
/// Handled asynchronously to prevent blocking the main UI thread.
final socketEnsureConnectedProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final service = ref.watch(socketServiceProvider);
  if (!service.isConnected) {
    try {
      await service.connect();
    } catch (e) {
      // ignore: avoid_print
      print('Failed to establish socket connection: $e');
    }
  }
});

// ========== Event Stream Providers ==========

/// Notifies when a new live auction session officially begins.
final auctionStartedProvider = StreamProvider.autoDispose<AuctionModel>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionModel>(
    'auctionStarted',
    (data) => AuctionModel.fromJson(data as Map<String, dynamic>),
  );
});

/// Notifies when an auction enters its "Preparing" or "Pre-start" phase.
final auctionPreStartedProvider = StreamProvider.autoDispose<AuctionModel>((
  ref,
) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionModel>(
    'auctionPreStarted',
    (data) => AuctionModel.fromJson(data as Map<String, dynamic>),
  );
});

/// Real-time stream of the number of active participants in an auction room.
final userCountUpdateProvider = StreamProvider.autoDispose<UserCountUpdate>((
  ref,
) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<UserCountUpdate>(
    'userCountUpdate',
    (data) => UserCountUpdate.fromJson(data as Map<String, dynamic>),
  );
});

/// Stream of all incoming chat comments and system notifications.
final newCommentProvider = StreamProvider.autoDispose<CommentEvent>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<CommentEvent>(
    'newComment',
    (data) => CommentEvent.fromJson(data as Map<String, dynamic>),
  );
});

/// Reactive state for the single most recent bid in a live session.
final currentBidStateProvider = StateProvider.autoDispose<AuctionBid?>((ref) {
  final bidEvent = ref.watch(newBidEventProvider);
  return bidEvent.valueOrNull?.newBid;
});

/// Reactive state for the authoritative expiry date received from the server pulse.
final latestExpiryDateStateProvider = StateProvider.autoDispose<DateTime?>((
  ref,
) {
  final bidEvent = ref.watch(newBidEventProvider);
  return bidEvent.valueOrNull?.expiryDate;
});

/// Stream provider for successful 'newBid' events.
/// 
/// This is the primary driver for bid-related UI updates.
final newBidEventProvider = StreamProvider.autoDispose<BidPlacedEvent>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<BidPlacedEvent>('newBid', (data) {
    return BidPlacedEvent.fromJson(data as Map<String, dynamic>);
  });
});

/// Utility to reset transient bid states when navigating between distinct auctions.
void resetNewBidStream(WidgetRef ref) {
  ref.read(currentBidStateProvider.notifier).state = null;
  ref.read(latestExpiryDateStateProvider.notifier).state = null;
}

/// Helper notifier for maintaining an ordered history of bids in the current session.
/// 
/// Encapsulates logic for merging authoritative lists and individual events.
class AccumulatedBidsNotifier extends StateNotifier<List<AuctionBid>> {
  AccumulatedBidsNotifier() : super([]);

  /// Overrides the entire history with an authoritative list from the server.
  /// Typically called after a room re-sync or pulse event.
  void updateAll(List<AuctionBid> bids) {
    state = bids;
  }

  /// Appends a single new bid to the history, performing a de-duplication check.
  void addBid(AuctionBid bid) {
    if (bid.id != null && state.any((b) => b.id == bid.id)) return;
    state = [bid, ...state];
  }
}

/// Provides an accumulated, sorted list of all bids received during the session.
/// 
/// Listens to [newBidEventProvider] and automatically incorporates updates 
/// from the server's authoritative `auctionBids` list.
final accumulatedBidsProvider =
    StateNotifierProvider.autoDispose<
      AccumulatedBidsNotifier,
      List<AuctionBid>
    >((ref) {
      final notifier = AccumulatedBidsNotifier();
      // Reactive binding: Update local list whenever a new bid event occurs
      ref.listen<AsyncValue<BidPlacedEvent>>(newBidEventProvider, (
        previous,
        next,
      ) {
        final event = next.valueOrNull;
        if (event != null) {
          if (event.auctionBids.isNotEmpty) {
            notifier.updateAll(event.auctionBids);
          } else {
            notifier.addBid(event.newBid);
          }
        }
      });
      return notifier;
    });

/// Notifies when an auction has been canceled by an administrator.
final auctionCanceledProvider = StreamProvider.autoDispose<AuctionModel>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionModel>(
    'auctionCanceled',
    (data) => AuctionModel.fromJson(data as Map<String, dynamic>),
  );
});

/// Notifies when an auction officially concludes and a winner is determined.
final auctionEndedProvider = StreamProvider.autoDispose<AuctionEndedEvent>((
  ref,
) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionEndedEvent>(
    'auctionEnded',
    (data) => AuctionEndedEvent.fromJson(data as Map<String, dynamic>),
  );
});

/// Notifies when a specific item unit within a multi-item auction has ended.
final auctionItemEndedProvider =
    StreamProvider.autoDispose<AuctionItemEndedEvent>((ref) {
      final service = ref.watch(socketServiceProvider);
      return service.getEventStream<AuctionItemEndedEvent>(
        'auctionItemEnded',
        (data) => AuctionItemEndedEvent.fromJson(data as Map<String, dynamic>),
      );
    });

/// High-level state provider for the most recent product transition event.
final auctionProductChangeProvider =
    StateProvider.autoDispose<AuctionProductChangeEvent?>((ref) {
      final productChange = ref.watch(_auctionProductChangeProvider);
      return productChange.valueOrNull;
    });

/// Internal stream for 'auction_change_product' events.
final _auctionProductChangeProvider =
    StreamProvider.autoDispose<AuctionProductChangeEvent>((ref) {
      final service = ref.watch(socketServiceProvider);
      return service.getEventStream<AuctionProductChangeEvent>(
        'auction_change_product',
        (data) =>
            AuctionProductChangeEvent.fromJson(data as Map<String, dynamic>),
      );
    });

/// Resets the persistent product change state.
void resetProductChangeStream(WidgetRef ref) {
  ref.read(auctionProductChangeProvider.notifier).state = null;
}

/// Global stream for handling business-logic errors emitted by the server.
final socketErrorProvider = StreamProvider.autoDispose<SocketErrorEvent>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<SocketErrorEvent>(
    'error',
    (data) => SocketErrorEvent.fromJson(data as Map<String, dynamic>),
  );
});

/// Notifies when a user's bid attempt is rejected (e.g., bid was too low).
final bidRejectedProvider = StreamProvider.autoDispose<BidRejectedEvent>((
  ref,
) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<BidRejectedEvent>(
    'bidRejected',
    (data) => BidRejectedEvent.fromJson(data as Map<String, dynamic>),
  );
});

/// Authoritative snapshot of the entire auction state.
/// 
/// Also seeds the rolling sequence counter [auctionSeqProvider] to facilitate 
/// authoritative gap detection.
final auctionSyncProvider = StreamProvider.autoDispose<AuctionModel>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.getEventStream<AuctionModel>(
    'auctionSync',
    (data) {
      final json = data as Map<String, dynamic>;
      final seqFromServer = json['seq'] as int?;
      if (seqFromServer != null) {
        // Asynchronously update sequence state to avoid provider loop errors
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

// ── Sequence Matching and Gap Detection ──────────────────────────────────────────

/// Tracks the last processed [seq] ID from the server broadcast.
/// 
/// Initialized to -1. Values 0+ are considered valid sequence IDs used to 
/// detect missed packets in real-time streams.
final auctionSeqProvider = StateProvider<int>((ref) => -1);

/// A background logic provider that monitors all sequenced streams for state gaps.
/// 
/// If an event arrives with a `seq` ID much higher than the last known one 
/// (e.g. last=10, incoming=12), it implicitly triggers a 'requestSync' emit 
/// to catch up on missed data.
final auctionGapDetectedProvider = Provider<void>((ref) {
  /// Compares the [incoming] sequence ID with the [last] known one.
  void checkSeq(int? incoming, int auctionId) {
    if (incoming == null) return;
    final last = ref.read(auctionSeqProvider);

    if (last == -1) {
      ref.read(auctionSeqProvider.notifier).state = incoming;
      return;
    }

    if (incoming <= last) return; // Ignore old or duplicate events

    if (incoming > last + 1) {
      // Gap detected: missed one or more packets
      assert(() {
        // ignore: avoid_print
        print('[SeqGap] auction=$auctionId gap=${incoming - last - 1} '  
              '(last=$last, received=$incoming) — triggering force sync');
        return true;
      }());
      try {
        ref.read(socketActionsProvider).requestSync(auctionId);
      } catch (_) {}
    }

    ref.read(auctionSeqProvider.notifier).state = incoming;
  }

  // Cross-reference all streams that provide sequence numbers
  ref.listen<AsyncValue<BidPlacedEvent>>(newBidEventProvider, (_, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    checkSeq(event.seq, event.newBid.auctionId ?? 0);
  });

  ref.listen<AsyncValue<AuctionItemEndedEvent>>(auctionItemEndedProvider, (_, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    checkSeq(event.seq, event.auction.id ?? 0);
  });

  ref.listen<AsyncValue<AuctionEndedEvent>>(auctionEndedProvider, (_, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    checkSeq(event.seq, event.auctionId);
  });
});

// ─────────────────────────────────────────────────────────────────────────────

/// High-level wrapper for emitting standardized socket events.
final socketActionsProvider = Provider.autoDispose<SocketActions>((ref) {
  final service = ref.watch(socketServiceProvider);
  return SocketActions._(service);
});

// ── State Broadcast Provider ───────────────────────────────────────────────────

/// Heartbeat stream providing the authoritative server source-of-truth.
/// 
/// Typically emitted every 2 seconds by the server to sync timers, top bids, 
/// and product statuses across all devices.
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

/// A command-pattern helper class for all outgoing WebSocket communication.
/// 
/// Consolidates all 'emit' logic in a central place to ensure consistent 
/// connectivity checks and payload formatting.
class SocketActions {
  final SocketService _service;

  const SocketActions._(this._service);

  /// Requests the server to transition an auction to the 'Live' state.
  Future<void> startLiveAuction(int auctionId, int userId) async {
    await _ensureConnected();
    _service.emitStartLiveAuction(auctionId, userId);
  }

  /// Registers interest in an auction room by joining its namespace.
  Future<void> joinAuction(int auctionId, int userId) async {
    await _ensureConnected();
    _service.emitJoinAuction(auctionId, userId);
  }

  /// Unregisters interest and stops receiving room-specific broadcasts.
  Future<void> leaveAuction(int auctionId, int userId) async {
    await _ensureConnected();
    _service.emitLeaveAuction(auctionId, userId);
  }

  /// Broadcasts a participant chat comment to the entire room.
  Future<void> sendComment(int auctionId, int userId, String comment) async {
    await _ensureConnected();
    _service.emitComment(auctionId, userId, comment);
  }

  /// Submits a competitive bid attempt for a specific product.
  Future<void> placeBid(
    int auctionId,
    int userId,
    double amount,
    int productId,
  ) async {
    await _ensureConnected();
    _service.emitPlaceBid(auctionId, userId, amount, productId);
  }

  /// Performs an administrative cancellation of the current auction session.
  Future<void> cancelAuction(int auctionId, int userId) async {
    await _ensureConnected();
    _service.emitCancelAuction(auctionId, userId);
  }

  /// Officially awards a product item to a winner.
  Future<void> awardAuction(int auctionId, int userId, String product) async {
    await _ensureConnected();
    _service.emitAwardingAuction(auctionId, userId, product);
  }

  /// Updates the metadata for the product currently being auctioned.
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

  /// Manually triggers an 'auctionSync' snapshot from the backend.
  /// 
  /// Usually called automatically by [auctionGapDetectedProvider].
  Future<void> requestSync(int auctionId) async {
    await _ensureConnected();
    _service.emitRequestSync(auctionId);
  }

  /// Internal: Verifies connectivity and handshakes before attempting an emit action.
  Future<void> _ensureConnected() async {
    if (!_service.isConnected) {
      try {
        await _service.connect();
      } catch (e) {
        // ignore: avoid_print
        print('Error ensuring socket connection: $e');
      }
    }
  }
}

