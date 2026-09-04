import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/auction_price_helpers.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

void main() {
  group('AuctionModel', () {
    test('fromJson should parse item_duration correctly', () {
      final json = {
        'id': 30,
        'title': 'Test Auction',
        'item_duration': 30,
        'type': 'Live',
      };

      final auction = AuctionModel.fromJson(json);

      expect(auction.itemDuration, 30);
    });

    test('fromJson should parse duration as fallback for item_duration', () {
      final json = {
        'id': 30,
        'title': 'Test Auction',
        'duration': 45,
        'type': 'Live',
      };

      final auction = AuctionModel.fromJson(json);

      expect(auction.itemDuration, 45);
    });

    test('toJson should include item_duration', () {
      final auction = AuctionModel(
        id: 30,
        titleAr: 'Test Auction',
        itemDuration: 30,
        isLiveAuction: true,
      );

      final json = auction.toJson();

      expect(json['item_duration'], 30);
    });
  });

  group('AuctionProducts', () {
    test('fromJson should parse item_duration correctly', () {
      final json = {'id': 1, 'product': 'Product 1', 'item_duration': 20};

      final product = AuctionProducts.fromJson(json);

      expect(product.itemDuration, 20);
    });

    test('fromJson parses lot_number aliases and string prices', () {
      final product = AuctionProducts.fromJson({
        'id': 7,
        'product_ar': 'بند',
        'bidPrice': 5,
        'minBidPrice': 200,
        'lot_number': '12',
      });

      expect(product.bidPrice, '5');
      expect(product.minBidPrice, '200');
      expect(product.lotNumber, 12);
    });

    test('fromJson parses isSold / is_sold without treating bids as a sale', () {
      final unsold = AuctionProducts.fromJson({
        'id': 3266,
        'bidPrice': 5,
        'isSold': false,
        'is_sold': 0,
        'bids': [
          {'id': 1, 'user_id': 10, 'bid': 90, 'product_id': 3266},
        ],
      });
      expect(unsold.isSold, isFalse);
      expect(unsold.bids, isNotEmpty);

      final sold = AuctionProducts.fromJson({
        'id': 2,
        'is_sold': 1,
      });
      expect(sold.isSold, isTrue);
    });

    test('fromJson accepts lotNumber / item_number aliases', () {
      expect(
        AuctionProducts.fromJson({'id': 1, 'lotNumber': 3}).lotNumber,
        3,
      );
      expect(
        AuctionProducts.fromJson({'id': 1, 'item_number': 9}).lotNumber,
        9,
      );
    });
  });

  group('auction_price_helpers', () {
    test('displayLotPrice prefers highest bid then bidPrice never reserve', () {
      final product = AuctionProducts(bidPrice: '5', minBidPrice: '200');

      expect(displayLotPrice(product), 5);
      expect(displayLotPrice(product, highestBid: 40), 40);
      expect(publicStartingPrice(product), 5);
    });

    test('displayLotNumber uses lot_number then fallback index', () {
      final withLot = AuctionProducts(lotNumber: 18);
      final withoutLot = AuctionProducts();

      expect(displayLotNumber(withLot, fallbackIndex: 1), 18);
      expect(displayLotNumber(withoutLot, fallbackIndex: 4), 4);
    });

    test('openingPriceFromAuction uses selected product bidPrice never reserve', () {
      final product = AuctionProducts(bidPrice: '10', minBidPrice: '400');

      expect(
        openingPriceFromAuction(
          auctionBidPrice: 99,
          selectedProduct: product,
        ),
        10,
      );
    });

    test('openingPriceFromAuction ignores reserve when bidPrice is missing', () {
      final product = AuctionProducts(bidPrice: '0', minBidPrice: '400');

      expect(
        openingPriceFromAuction(
          auctionBidPrice: 5,
          selectedProduct: product,
        ),
        5,
      );
      expect(
        openingPriceFromAuction(
          auctionBidPrice: 0,
          selectedProduct: product,
        ),
        0,
      );
    });
  });
}
