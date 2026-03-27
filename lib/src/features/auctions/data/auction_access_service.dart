import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_access_model.dart';

/// Shared utility for checking and requesting auction access.
/// Screens should call these methods and handle UI updates themselves.
class AuctionAccessService {
  final AuctionsRepository _repository;

  AuctionAccessService(this._repository);

  /// Returns a status string: GRANTED, PENDING, DENIED, REQUIRED, ERROR.
  /// Handles admin shortcut and not-logged-in shortcut internally.
  Future<String> checkAccess({
    required int auctionId,
    int? auctionOwnerId,
  }) async {
    // Admin shortcut
    if (auctionOwnerId != null &&
        CachedVariables.userId != null &&
        auctionOwnerId == CachedVariables.userId) {
      return 'GRANTED';
    }

    // Not logged in
    if (CachedVariables.userId == null) {
      return 'REQUIRED';
    }

    try {
      final response = await _repository.checkUserAccess(
        CachedVariables.userId!,
        auctionId,
      );
      return response.status.toUpperCase();
    } catch (e) {
      debugPrint("Error checking auction access: $e");
      return 'ERROR';
    }
  }

  /// Requests access. Returns the new status string.
  /// Returns 'LOGIN_REQUIRED' if user is not logged in.
  Future<String> requestAccess({required int auctionId}) async {
    if (CachedVariables.userId == null) {
      return 'LOGIN_REQUIRED';
    }

    try {
      final response = await _repository.requestAccess(
        RequestAuctionAccessDto(
          userId: CachedVariables.userId!,
          auctionId: auctionId,
        ),
      );
      return response.status.toUpperCase();
    } catch (e) {
      debugPrint("Error requesting auction access: $e");
      return 'ERROR';
    }
  }
}

final auctionAccessServiceProvider = Provider<AuctionAccessService>((ref) {
  return AuctionAccessService(ref.read(productsRepositoryProvider));
});
