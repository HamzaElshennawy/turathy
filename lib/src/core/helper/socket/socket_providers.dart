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

// ========== Action Providers ==========

/// Provider for socket actions (emit events)
final socketActionsProvider = Provider.autoDispose<SocketActions>((ref) {
  final service = ref.watch(socketServiceProvider);
  return SocketActions._(service);
});

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

  /// Ensure socket is connected before performing actions
  Future<void> _ensureConnected() async {
    if (!_service.isConnected) {
      await _service.connect();
    }
  }
}
