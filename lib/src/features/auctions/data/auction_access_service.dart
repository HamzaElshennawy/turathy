import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/data/auction_access_status.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_access_model.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';

export 'auction_access_status.dart';

/// Shared utility for checking and requesting auction access.
class AuctionAccessService {
  final Ref _ref;
  final AuctionsRepository _repository;
  Future<String>? _inFlightRequest;

  AuctionAccessService(this._ref, this._repository);

  String? _profileGateStatus({int? auctionOwnerId}) {
    if (auctionOwnerId != null &&
        CachedVariables.userId != null &&
        auctionOwnerId == CachedVariables.userId) {
      return null;
    }

    final currentUser = _ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) {
      return null;
    }

    final missing = currentUser.missingFields ?? const <String>[];
    if (currentUser.isProfileComplete == false || missing.isNotEmpty) {
      return 'PROFILE_INCOMPLETE';
    }

    final nickname = currentUser.nickname?.trim() ?? '';
    if (nickname.isEmpty) {
      return 'NICKNAME_REQUIRED';
    }

    final approval = (currentUser.auctionAccessStatus ?? '').toUpperCase();
    if (approval == 'BLOCKED') {
      return 'DENIED';
    }

    return null;
  }

  Future<String> checkAccess({
    required int auctionId,
    int? auctionOwnerId,
  }) async {
    if (auctionOwnerId != null &&
        CachedVariables.userId != null &&
        auctionOwnerId == CachedVariables.userId) {
      return 'GRANTED';
    }

    if (CachedVariables.userId == null) {
      return 'REQUIRED';
    }

    final profileGateStatus = _profileGateStatus(auctionOwnerId: auctionOwnerId);
    if (profileGateStatus != null) {
      return profileGateStatus;
    }

    try {
      final response = await _repository.checkUserAccess(
        CachedVariables.userId!,
        auctionId,
      );
      return normalizeAuctionAccessStatus(response.status);
    } catch (e) {
      debugPrint('Error checking auction access: $e');
      return 'ERROR';
    }
  }

  Future<String> requestAccess({required int auctionId}) async {
    if (CachedVariables.userId == null) {
      return 'LOGIN_REQUIRED';
    }

    final profileGateStatus = _profileGateStatus();
    if (profileGateStatus != null) {
      return profileGateStatus;
    }

    final existing = _inFlightRequest;
    if (existing != null) return existing;

    final pending = () async {
      try {
        final response = await _repository.requestAccess(
          RequestAuctionAccessDto(
            userId: CachedVariables.userId!,
            auctionId: auctionId,
          ),
        );
        return normalizeAuctionAccessStatus(response.status);
      } catch (e) {
        debugPrint('Error requesting auction access: $e');
        return 'ERROR';
      }
    }();

    _inFlightRequest = pending;
    try {
      return await pending;
    } finally {
      if (identical(_inFlightRequest, pending)) {
        _inFlightRequest = null;
      }
    }
  }
}

final auctionAccessServiceProvider = Provider<AuctionAccessService>((ref) {
  return AuctionAccessService(ref, ref.read(productsRepositoryProvider));
});
