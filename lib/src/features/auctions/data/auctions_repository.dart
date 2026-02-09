import 'dart:async';
import 'package:turathy/src/features/home/presentation/home_screen/widgets/products_widget/auctions_filter_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../authintication/data/auth_repository.dart';
import '../../search/domain/filter_state.dart';
import '../../search/presentation/widgets/filter_widget/filter_widget_controller.dart';
import '../domain/auction_model.dart';
import '../domain/winning_auction_model.dart';

class AuctionsRepository {
  Future<List<AuctionModel>> getAllAuctions([FilterState? filters]) async {
    final lastFilters = (filters?.toMap() ?? {});
    lastFilters.addAll({'limit': '100'});
    final result = await DioHelper.getData(
      url: EndPoints.getAllAuctions,
      token: CachedVariables.token,
      query: lastFilters,
    );
    if (result.statusCode == 200) {
      List<AuctionModel> products = [];
      for (var item in result.data['data']) {
        products.add(AuctionModel.fromJson(item));
      }
      return products;
    } else {
      String message =
          result.data['error'] ?? 'An error occurred while fetching auctions';
      throw AuthException(message, result.statusCode);
    }
  }

  Future<List<AuctionModel>> getAuctionsByCategory([
    FilterState? filters,
  ]) async {
    final lastFilters = (filters?.toMap() ?? {});
    lastFilters.addAll({'limit': '100'});
    final result = await DioHelper.getData(
      url: (filters == null || filters.selectedCategoryID == null)
          ? EndPoints.getAllAuctions
          : EndPoints.getAuctionsByCategory(id: filters.selectedCategoryID!),
      token: CachedVariables.token,
      query: lastFilters,
    );
    if (result.statusCode == 200) {
      List<AuctionModel> products = [];
      for (var item in result.data['data']) {
        products.add(AuctionModel.fromJson(item));
      }
      return products;
    } else {
      String message =
          result.data['error'] ?? 'An error occurred while fetching auctions';
      throw AuthException(message, result.statusCode);
    }
  }

  Future<AuctionModel> getAuctionByID(int auctionID) async {
    final result = await DioHelper.getData(
      url: EndPoints.getAuctionByID(id: auctionID),
      token: CachedVariables.token,
    );
    if (result.statusCode == 200) {
      return AuctionModel.fromJson(result.data['data']);
    } else {
      String message =
          result.data['error'] ??
          'An error occurred while fetching auction details';
      throw AuthException(message, result.statusCode);
    }
  }

  Future<String> getAgoraToken(int auctionID, bool isPublisher) async {
    final result = await DioHelper.getData(
      query: {
        'channelName': 'auction_$auctionID',
        'uid': CachedVariables.userId.toString(),
        'isPublisher': isPublisher.toString(),
      },
      url: EndPoints.getAgoraToken,
      token: CachedVariables.token,
    );
    if (result.statusCode == 200) {
      return result.data['data'];
    } else {
      String message =
          result.data['error'] ??
          'An error occurred while fetching agora token';
      throw AuthException(message, result.statusCode);
    }
  }

  // get user auctions
  Future<List<AuctionModel>> getUserAuctions(String auctionType) async {
    final result = await DioHelper.getData(
      url: EndPoints.getUserAuctions,
      token: CachedVariables.token,
      query: {
        'type': auctionType,
        'limit': '100',
        'user_id': CachedVariables.userId.toString(),
      },
    );
    if (result.statusCode == 200) {
      List<AuctionModel> auctions = [];
      for (var item in result.data['data']) {
        auctions.add(AuctionModel.fromJson(item));
      }
      return auctions;
    } else {
      String message =
          result.data['error'] ??
          'An error occurred while fetching user auctions';
      throw AuthException(message, result.statusCode);
    }
  }

  Future<List<WinningAuctionModel>> getWinningAuctions() async {
    final result = await DioHelper.getData(
      url: EndPoints.getWiningAuctions,
      token: CachedVariables.token,
      query: {'user_id': CachedVariables.userId.toString()},
    );
    if (result.statusCode == 200) {
      List<WinningAuctionModel> auctions = [];
      final data = result.data['data'] as Map<String, dynamic>;
      data.forEach((key, value) {
        for (var item in value) {
          auctions.add(WinningAuctionModel.fromJson(item));
        }
      });
      return auctions;
    } else {
      String message =
          result.data['error'] ??
          'An error occurred while fetching winning auctions';
      throw AuthException(message, result.statusCode);
    }
  }
}

final productsRepositoryProvider = Provider<AuctionsRepository>((ref) {
  return AuctionsRepository();
});

final filteredAuctionsProvider = FutureProvider<List<AuctionModel>>((
  ref,
) async {
  final timer = Timer(const Duration(minutes: 3), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
  });

  final status = ref.watch(auctionsFilterProvider);

  return ref
      .watch(productsRepositoryProvider)
      .getAllAuctions(
        FilterState(isLiveAuctionsSelected: true, auctionStatus: status),
      );
});

final homeLiveAuctionsProvider = FutureProvider<List<AuctionModel>>((
  ref,
) async {
  final timer = Timer(const Duration(minutes: 3), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
  });

  return ref
      .watch(productsRepositoryProvider)
      .getAllAuctions(
        FilterState(isLiveAuctionsSelected: true, auctionStatus: 'current'),
      );
});
final openAuctionsProvider = FutureProvider<List<AuctionModel>>((ref) async {
  final timer = Timer(const Duration(minutes: 3), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
  });
  return ref
      .watch(productsRepositoryProvider)
      .getAllAuctions(FilterState(isLiveAuctionsSelected: false));
});

// search products with filter provider
final searchProductsProvider = FutureProvider<List<AuctionModel>>((ref) async {
  final filters = ref.read(filterWidgetControllerProvider);
  final timer = Timer(const Duration(minutes: 10), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
  });
  return ref.watch(productsRepositoryProvider).getAuctionsByCategory(filters);
});

final auctionDetailsProvider = FutureProvider.autoDispose
    .family<AuctionModel, int>((ref, auctionID) async {
      return ref.watch(productsRepositoryProvider).getAuctionByID(auctionID);
    });

final agoraTokenProvider = FutureProvider.autoDispose
    .family<String, AgoraTokenRequest>((ref, request) async {
      return ref
          .watch(productsRepositoryProvider)
          .getAgoraToken(request.auctionID, request.isPublisher);
    });

final userAuctionsProvider = FutureProvider.autoDispose
    .family<List<AuctionModel>, String>((ref, type) async {
      return ref.watch(productsRepositoryProvider).getUserAuctions(type);
    });

final userWinningAuctionsProvider =
    FutureProvider.autoDispose<List<WinningAuctionModel>>((ref) async {
      return ref.watch(productsRepositoryProvider).getWinningAuctions();
    });

class AgoraTokenRequest {
  final int auctionID;
  final bool isPublisher;

  //<editor-fold desc="Data Methods">
  const AgoraTokenRequest({required this.auctionID, required this.isPublisher});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgoraTokenRequest &&
          runtimeType == other.runtimeType &&
          auctionID == other.auctionID &&
          isPublisher == other.isPublisher);

  @override
  int get hashCode => auctionID.hashCode ^ isPublisher.hashCode;

  @override
  String toString() {
    return 'AgoraTokenRequest{'
        ' auctionID: $auctionID,'
        ' isPublisher: $isPublisher,'
        '}';
  }

  AgoraTokenRequest copyWith({int? auctionID, bool? isPublisher}) {
    return AgoraTokenRequest(
      auctionID: auctionID ?? this.auctionID,
      isPublisher: isPublisher ?? this.isPublisher,
    );
  }

  Map<String, dynamic> toMap() {
    return {'auctionID': auctionID, 'isPublisher': isPublisher};
  }

  factory AgoraTokenRequest.fromMap(Map<String, dynamic> map) {
    return AgoraTokenRequest(
      auctionID: map['auctionID'] as int,
      isPublisher: map['isPublisher'] as bool,
    );
  }

  //</editor-fold>
}
