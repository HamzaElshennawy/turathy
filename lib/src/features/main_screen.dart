/// {@category Navigation}
///
/// The central navigation and state orchestration shell of the application.
///
/// [MainScreen] serves as the root container for the primary application features,
/// providing a persistent [NavigationBar] and managing the lifecycle of:
/// - [HomeScreen]
/// - [AllAuctionsScreen]
/// - [StoreScreen]
/// - [OrdersListScreen]
/// - [MoreScreen]
///
/// It also handles global responsibilities such as connectivity monitoring,
/// real-time socket connections, and scroll-linked UI animations.
///
// ignore_for_file: unused_element_parameter

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/all_auctions_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_images/app_images.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';
import 'package:turathy/src/features/more/presentation/more_screen.dart';

import 'package:turathy/src/features/notifications/presentation/notifications_controller.dart';
import 'package:turathy/src/features/notifications/presentation/notifications_screen.dart';

import 'package:turathy/src/features/orders/presentation/orders_list_screen.dart';

import '../core/constants/app_functions/app_functions.dart';
import '../core/constants/app_strings/app_strings.dart';
import 'auctions/data/auctions_repository.dart';

import 'authintication/presentation/auth_controller.dart';
import 'home/data/category_repository.dart';
import 'home/presentation/home_screen/home_screen.dart';
import 'store/presentation/store_screen.dart';

/// The main scaffold of the app containing the navigation logic.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  /// Currently active navigation index based on [mainScreenTabIndexProvider].
  int _selectedIndex = 0;

  /// Controls the horizontal paging between main feature screens.
  late final PageController pageController;

  /// Tracks scrolling on the Home screen to drive AppBar animations.
  late final ScrollController _homeScrollController;

  /// Tracks scrolling on the Auctions screen to show/hide the filter FAB.
  late final ScrollController _auctionsScrollController;

  /// Tracks the vertical offset of the Home scroll view.
  double _scrollOffset = 0.0;

  /// Tracks the vertical offset of the Auctions scroll view.
  double _auctionsScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(mainScreenTabIndexProvider);
    _selectedIndex = initialPage;
    pageController = PageController(initialPage: initialPage);
    pageController.addListener(_handlePageChange);

    _homeScrollController = ScrollController();
    _homeScrollController.addListener(_handleScroll);

    _auctionsScrollController = ScrollController();
    _auctionsScrollController.addListener(_handleAuctionsScroll);
  }

  /// Updates local state when the [PageView] settles on a new page.
  void _handlePageChange() {
    if (!mounted) return;
    final page = pageController.page?.round() ?? 0;
    if (_selectedIndex != page) {
      setState(() {
        _selectedIndex = page;
      });
    }
  }

  /// Updates [_scrollOffset] for the Home tab animations.
  void _handleScroll() {
    if (!mounted) return;
    if (_selectedIndex == 0) {
      if (_homeScrollController.hasClients) {
        setState(() {
          _scrollOffset = _homeScrollController.offset;
        });
      }
    }
  }

  /// Updates [_auctionsScrollOffset] for the Auctions tab FAB.
  void _handleAuctionsScroll() {
    if (!mounted) return;
    if (_selectedIndex == 1) {
      if (_auctionsScrollController.hasClients) {
        setState(() {
          _auctionsScrollOffset = _auctionsScrollController.offset;
        });
      }
    }
  }

  @override
  void dispose() {
    pageController.removeListener(_handlePageChange);
    _homeScrollController.removeListener(_handleScroll);
    _homeScrollController.dispose();
    _auctionsScrollController.removeListener(_handleAuctionsScroll);
    _auctionsScrollController.dispose();
    super.dispose();
  }

  /// Tracks if a connectivity error dialog is currently visible.
  bool _isDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    // ── Infrastructure Initialization ─────────────────────────────────────
    try {
      ref.read(socketServiceProvider).connect();
    } catch (e) {
      debugPrint('Failed to connect socket in MainScreen: $e');
    }

    // ── Auth Listeners ────────────────────────────────────────────────────
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasValue &&
          next.value == null &&
          next.error == null &&
          !next.isLoading) {
        // Handle post-signout logic here if needed
      } else if (next.error != null) {
        AppFunctions.showSnackBar(
          context: context,
          message: next.error.toString(),
        );
      }
    });

    // ── Connectivity Monitoring ───────────────────────────────────────────
    ref.listen(connectionProvider, (previous, next) {
      final hasInternet =
          (next.value?.contains(ConnectivityResult.mobile) ?? false) ||
          (next.value?.contains(ConnectivityResult.wifi) ?? false) ||
          (next.value?.contains(ConnectivityResult.ethernet) ?? false);

      if (!hasInternet) {
        showAdaptiveDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _ConnectivityErrorDialog(),
        );
        _isDialogOpen = true;
      } else {
        if (_isDialogOpen) {
          Navigator.of(context).pop();
          _isDialogOpen = false;
          // Refresh data on reconnection
          ref.invalidate(homeLiveAuctionsProvider);
          ref.invalidate(searchProductsProvider);
          ref.invalidate(getAllCategoriesProvider);
        }
      }
    });

    // ── Navigation Sync ──────────────────────────────────────────────────
    ref.listen(mainScreenTabIndexProvider, (previous, next) {
      if (next != _selectedIndex) {
        setState(() => _selectedIndex = next);
        if (pageController.hasClients) {
          pageController.jumpToPage(next);
        }
      }
    });

    final authController = ref.watch(authControllerProvider);

    // ── Scroll Animation Calculations ─────────────────────────────────────
    final double shrinkProgress = (_scrollOffset / 100).clamp(0.0, 1.0);
    final double appBarHeight = _selectedIndex == 0
        ? (120 - (45 * shrinkProgress))
        : 75;
    final double avatarRadius = _selectedIndex == 0
        ? (30 - (8 * shrinkProgress))
        : 22;
    final double welcomeFontSize = _selectedIndex == 0
        ? (24 - (6 * shrinkProgress))
        : 18;
    final double notificationIconSize = _selectedIndex == 0
        ? (32 - (8 * shrinkProgress))
        : 24;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).colorScheme.primary.brighten(20),
      ),
      child: PopScope(
        canPop: _selectedIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_selectedIndex != 0) {
            ref.read(mainScreenTabIndexProvider.notifier).state = 0;
          }
        },
        child: Scaffold(
          floatingActionButton:
              _selectedIndex == 1 && _auctionsScrollOffset > 50
              ? FloatingActionButton(
                  onPressed: () {
                    // TODO: Trigger filter from AllAuctionsScreen
                  },
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.tune, color: Colors.white),
                )
              : null,
          appBar: AppBar(
            leadingWidth: _selectedIndex >= 1 ? 80 : 0,
            toolbarHeight: appBarHeight,
            leading: _selectedIndex >= 1
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      AppImages.logo,
                      width: 70,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                : null,
            title: _selectedIndex < 1
                ? Row(
                    children: [
                      _UserAvatar(
                        radius: avatarRadius,
                        name: authController.valueOrNull?.name,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👋 ${AppStrings.hi.tr()}, ${authController.valueOrNull?.name ?? 'User'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey,
                                  fontSize: welcomeFontSize,
                                ),
                          ),
                        ],
                      ),
                    ],
                  )
                : null,
            actions: [
              _NotificationIcon(notificationIconSize: notificationIconSize),
            ],
          ),
          extendBody: true,
          bottomNavigationBar: _buildFloatingBottomBar(),
          body: SafeArea(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              children: [
                HomeScreen(scrollController: _homeScrollController),
                AllAuctionsScreen(scrollController: _auctionsScrollController),
                StoreScreen(),
                OrdersListScreen(),
                MoreScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the stylized, floating bottom navigation bar.
  Widget _buildFloatingBottomBar() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Visual padding for floating appearance
        Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(),
        ),
        Container(
          margin: const EdgeInsets.only(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDCCAA7),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              height: 70,
              elevation: 1,
              backgroundColor: const Color(0xFFFDFDF5),
              surfaceTintColor: Colors.transparent,
              indicatorColor: const Color(0xFFE8F5E9),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 500),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                ref.read(mainScreenTabIndexProvider.notifier).state = index;
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined, size: 24),
                  selectedIcon: const Icon(
                    Icons.home,
                    size: 28,
                    color: Color(0xFF1B5E20),
                  ),
                  label: AppStrings.home.tr(),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.gavel_outlined, size: 24),
                  selectedIcon: const Icon(
                    Icons.gavel,
                    size: 28,
                    color: Color(0xFF1B5E20),
                  ),
                  label: AppStrings.auctions.tr(),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.store_outlined, size: 24),
                  selectedIcon: const Icon(
                    Icons.store,
                    size: 28,
                    color: Color(0xFF1B5E20),
                  ),
                  label: AppStrings.store.tr(),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined, size: 24),
                  selectedIcon: const Icon(
                    Icons.inventory_2,
                    size: 28,
                    color: Color(0xFF1B5E20),
                  ),
                  label: AppStrings.myOrders.tr(),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.menu_outlined, size: 24),
                  selectedIcon: const Icon(
                    Icons.menu,
                    size: 28,
                    color: Color(0xFF1B5E20),
                  ),
                  label: AppStrings.more.tr(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A reactive notification icon with an unread badge.
class _NotificationIcon extends ConsumerWidget {
  final double notificationIconSize;

  const _NotificationIcon({required this.notificationIconSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start listening to notifications
    ref.watch(notificationsNotifierProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              size: notificationIconSize,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// A circular avatar that fallback to the user's first initial if no image is available.
class _UserAvatar extends StatelessWidget {
  /// Remote URL for the user's profile image.
  final String? image;

  /// The user's name used for the fallback initial.
  final String? name;

  /// The radius of the avatar circle.
  final double radius;

  const _UserAvatar({this.image, this.name, this.radius = 30});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: image != null ? NetworkImage(image!) : null,
      child: image == null
          ? Text(
              name?.isNotEmpty == true ? name![0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            )
          : CachedNetworkImage(
              imageUrl: image!,
              memCacheHeight: 150,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
    );
  }
}

/// A standardized dialog for reporting connectivity issues in the shell.
class _ConnectivityErrorDialog extends StatelessWidget {
  const _ConnectivityErrorDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      title: Text('No Internet Connection', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 50, color: Colors.red),
          SizedBox(height: 12),
          Text(
            'Please check your internet connection and try again',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Provider for tracking and persisting the active bottom navigation tab.
final mainScreenTabIndexProvider = StateProvider<int>((ref) => 0);

/// Stream provider for monitoring system-wide network connectivity changes.
final connectionProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged;
});
