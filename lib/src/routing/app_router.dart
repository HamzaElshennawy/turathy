/// {@category Navigation}
///
/// The central routing configuration for the Turathy application.
/// 
/// This file defines the global [GoRouter] instance, managing path-to-widget 
/// mappings and top-level navigation logic (initial location, param parsing).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/authintication/presentation/sign_in_screen.dart';
import '../features/authintication/presentation/sign_up_screen.dart';
import '../features/authintication/presentation/complete_profile_screen.dart';
import '../features/main_screen.dart';
import '../features/auctions/presentation/auction_screen/live_auction_screen.dart';
import '../features/auctions/presentation/auction_screen/auction_details_wrapper.dart';
import '../features/orders/presentation/orders_list_screen.dart';
import '../features/orders/presentation/order_details_wrapper.dart';
import '../features/products/presentation/product_details_wrapper.dart';
import '../features/splash_screen/splash_screen.dart';
import 'rout_constants.dart';

/// A global key used for accessing the root navigator without [BuildContext].
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The primary application router using the `go_router` package.
final goRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RouteConstants.init,
  debugLogDiagnostics: true,
  routes: [
    // ── Entry Point ──────────────────────────────────────────────────────
    GoRoute(
      path: RouteConstants.init,
      name: RouteConstants.init,
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Authentication ───────────────────────────────────────────────────
    GoRoute(
      path: RouteConstants.signIn,
      name: RouteConstants.signIn,
      builder: (context, state) => SignInScreen(),
    ),
    GoRoute(
      path: RouteConstants.signUp,
      name: RouteConstants.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: RouteConstants.completeProfile,
      name: RouteConstants.completeProfile,
      builder: (context, state) => const CompleteProfileScreen(),
    ),

    // ── Main Content ─────────────────────────────────────────────────────
    GoRoute(
      path: RouteConstants.home,
      name: RouteConstants.home,
      builder: (context, state) => const MainScreen(),
      onExit: (context, _) async {
        /// Shows a confirmation dialog when the user tries to exit the shell.
        final result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Are you sure you want to exit?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Go Back'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Confirm'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
        return Future.value(result ?? false);
      },
    ),

    // ── Features & Details ───────────────────────────────────────────────
    GoRoute(
      path: RouteConstants.liveAuction,
      name: RouteConstants.liveAuction,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return LiveAuctionScreen(auctionId: int.parse(id!));
      },
    ),
    GoRoute(
      path: RouteConstants.productDetails,
      name: RouteConstants.productDetails,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return ProductDetailsWrapper(productId: int.parse(id!));
      },
    ),
    GoRoute(
      path: RouteConstants.orders,
      name: RouteConstants.orders,
      builder: (context, state) => const OrdersListScreen(),
    ),
    GoRoute(
      path: RouteConstants.orderDetails,
      name: RouteConstants.orderDetails,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return OrderDetailsWrapper(orderId: int.parse(id!));
      },
    ),
    GoRoute(
      path: RouteConstants.auctionDetails,
      name: RouteConstants.auctionDetails,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AuctionDetailsWrapper(auctionId: int.parse(id!));
      },
    ),
  ],
);

