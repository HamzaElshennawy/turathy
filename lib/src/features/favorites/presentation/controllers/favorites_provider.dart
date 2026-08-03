import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/favorites/data/favorites_repository.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';

class FavoritesState {
  final List<ProductModel> likedProducts;
  final List<AuctionModel> likedAuctions;
  final List<AuctionProducts> watchedLots;
  final Set<int> likedProductIds;
  final Set<int> likedAuctionIds;
  final Set<int> watchedLotIds;

  FavoritesState({
    this.likedProducts = const [],
    this.likedAuctions = const [],
    this.watchedLots = const [],
  })  : likedProductIds = likedProducts.map((e) => e.id).toSet(),
        likedAuctionIds = likedAuctions
            .where((e) => e.id != null)
            .map((e) => e.id!)
            .toSet(),
        watchedLotIds = watchedLots
            .where((e) => e.id != null)
            .map((e) => e.id!)
            .toSet();

  FavoritesState copyWith({
    List<ProductModel>? likedProducts,
    List<AuctionModel>? likedAuctions,
    List<AuctionProducts>? watchedLots,
  }) {
    return FavoritesState(
      likedProducts: likedProducts ?? this.likedProducts,
      likedAuctions: likedAuctions ?? this.likedAuctions,
      watchedLots: watchedLots ?? this.watchedLots,
    );
  }
}

class FavoritesController extends StateNotifier<AsyncValue<FavoritesState>> {
  final FavoritesRepository _repository;

  FavoritesController(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final products = await _repository.getLikedProducts();
      final auctions = await _repository.getLikedAuctions();
      final lots = await _repository.getWatchedLots();
      state = AsyncValue.data(
        FavoritesState(
          likedProducts: products,
          likedAuctions: auctions,
          watchedLots: lots,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isProductLiked(int id) {
    return state.maybeWhen(
      data: (data) => data.likedProductIds.contains(id),
      orElse: () => false,
    );
  }

  bool isAuctionLiked(int id) {
    return state.maybeWhen(
      data: (data) => data.likedAuctionIds.contains(id),
      orElse: () => false,
    );
  }

  bool isLotWatched(int id) {
    return state.maybeWhen(
      data: (data) => data.watchedLotIds.contains(id),
      orElse: () => false,
    );
  }

  Future<void> toggleLikeProduct(ProductModel product) async {
    final currentState = state.value;
    if (currentState == null) return;

    final isLiked = currentState.likedProductIds.contains(product.id);
    final List<ProductModel> newProducts = List.from(
      currentState.likedProducts,
    );

    if (isLiked) {
      newProducts.removeWhere((element) => element.id == product.id);
    } else {
      newProducts.add(product);
    }

    state = AsyncValue.data(currentState.copyWith(likedProducts: newProducts));

    try {
      await _repository.toggleLike(itemId: product.id, type: 'product');
    } catch (e) {
      state = AsyncValue.data(currentState);
    }
  }

  Future<void> toggleLikeAuction(AuctionModel auction) async {
    if (auction.id == null) return;
    final currentState = state.value;
    if (currentState == null) return;

    final isLiked = currentState.likedAuctionIds.contains(auction.id!);
    final List<AuctionModel> newAuctions = List.from(
      currentState.likedAuctions,
    );

    if (isLiked) {
      newAuctions.removeWhere((element) => element.id == auction.id);
    } else {
      newAuctions.add(auction);
    }

    state = AsyncValue.data(currentState.copyWith(likedAuctions: newAuctions));

    try {
      await _repository.toggleLike(itemId: auction.id!, type: 'auction');
    } catch (e) {
      state = AsyncValue.data(currentState);
    }
  }

  Future<void> toggleWatchLot(AuctionProducts lot) async {
    if (lot.id == null) return;
    final currentState = state.value;
    if (currentState == null) return;

    final isWatched = currentState.watchedLotIds.contains(lot.id!);
    final List<AuctionProducts> newLots = List.from(currentState.watchedLots);

    if (isWatched) {
      newLots.removeWhere((element) => element.id == lot.id);
    } else {
      newLots.add(lot);
    }

    state = AsyncValue.data(currentState.copyWith(watchedLots: newLots));

    try {
      await _repository.toggleLike(itemId: lot.id!, type: 'auction_product');
    } catch (e) {
      state = AsyncValue.data(currentState);
    }
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, AsyncValue<FavoritesState>>((
      ref,
    ) {
      final repository = ref.watch(favoritesRepositoryProvider);
      return FavoritesController(repository);
    });
