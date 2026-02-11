import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/authintication/presentation/sign_in_screen.dart';
import '../features/authintication/presentation/sign_up_screen.dart';
import '../features/main_screen.dart';
import '../features/auctions/presentation/auction_screen/live_auction_screen.dart';
import '../features/orders/presentation/orders_list_screen.dart';
import '../features/products/presentation/product_details_wrapper.dart';
import '../features/splash_screen/splash_screen.dart';
import 'rout_constants.dart';

final goRouter = GoRouter(
  initialLocation: RouteConstants.init,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: RouteConstants.init,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteConstants.signIn,
      builder: (context, state) => SignInScreen(),
    ),
    GoRoute(
      path: RouteConstants.home,
      builder: (context, state) => const MainScreen(),
      onExit: (context, _) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Are you sure you want to exit?'),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Go Back'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Confirm'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
        //The return type 'Future<bool?>' isn't a 'FutureOr<bool>', as required by the closure's context. (Documentation)
        return Future.value(result);
      },
    ),
    GoRoute(
      path: RouteConstants.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: RouteConstants.liveAuction,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return LiveAuctionScreen(auctionId: int.parse(id!));
      },
    ),
    GoRoute(
      path: RouteConstants.productDetails,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return ProductDetailsWrapper(productId: int.parse(id!));
      },
    ),
    GoRoute(
      path: RouteConstants.orders,
      builder: (context, state) => const OrdersListScreen(),
    ),
  ],
);
