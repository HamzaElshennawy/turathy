import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/favorites/data/favorites_repository.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';

class FavoritesState {
  final List<ProductModel> likedProducts;
  final List<AuctionModel> likedAuctions;
  final Set<int> likedProductIds;
  final Set<int> likedAuctionIds;

  FavoritesState({this.likedProducts = const [], this.likedAuctions = const []})
    : likedProductIds = likedProducts.map((e) => e.id).toSet(),
      likedAuctionIds = likedAuctions
          .where((e) => e.id != null)
          .map((e) => e.id!)
          .toSet();

  FavoritesState copyWith({
    List<ProductModel>? likedProducts,
    List<AuctionModel>? likedAuctions,
  }) {
    return FavoritesState(
      likedProducts: likedProducts ?? this.likedProducts,
      likedAuctions: likedAuctions ?? this.likedAuctions,
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
      state = AsyncValue.data(
        FavoritesState(likedProducts: products, likedAuctions: auctions),
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

    // Optimistic update
    state = AsyncValue.data(currentState.copyWith(likedProducts: newProducts));

    try {
      await _repository.toggleLike(itemId: product.id, type: 'product');
    } catch (e) {
      // Revert on error
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

    // Optimistic update
    state = AsyncValue.data(currentState.copyWith(likedAuctions: newAuctions));

    try {
      await _repository.toggleLike(itemId: auction.id!, type: 'auction');
    } catch (e) {
      // Revert on error
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
