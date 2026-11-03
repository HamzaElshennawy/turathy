import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/data/auction_payments_repository.dart';

void main() {
  test('a guest does not load my payments', () {
    expect(customerCanLoadPayments(null), isFalse);
    expect(customerCanLoadPayments(''), isFalse);
    expect(customerCanLoadPayments('   '), isFalse);
    expect(customerCanLoadPayments('customer-jwt'), isTrue);
  });
}
