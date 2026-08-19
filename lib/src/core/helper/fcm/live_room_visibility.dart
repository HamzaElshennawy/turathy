import 'package:flutter/foundation.dart';

/// Whether the customer is currently on the live auction room screen.
///
/// Kept out of [LiveAuctionScreen] / [FCMService] to avoid import cycles.
class LiveRoomVisibility {
  LiveRoomVisibility._();

  static final ValueNotifier<bool> isViewing = ValueNotifier(false);
}
