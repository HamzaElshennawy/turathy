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
import '../core/constants/app_sizes.dart';
import '../core/constants/app_strings/app_strings.dart';
import 'auctions/data/auctions_repository.dart';

import 'authintication/presentation/auth_controller.dart';
import 'home/data/category_repository.dart';
import 'home/presentation/home_screen/home_screen.dart';
import 'store/presentation/store_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final PageController pageController;

  @override
  void initState() {
    pageController = ref.read(pageControllerProvider);
    super.initState();
    pageController.addListener(() {
      setState(() {
        _selectedIndex = pageController.page!.toInt();
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  bool _isDialogOpen = false;
  @override
  Widget build(BuildContext context) {
    ref.read(socketServiceProvider).connect();
    // ref.read(connectionProvider);
    // signOut redirect to login screen;
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasValue &&
          next.value == null &&
          next.error == null &&
          !next.isLoading) {
        // Navigator.of(context).push(MaterialPageRoute(
        //   builder: (context) => SignInScreen(),
        // ));
      } else if (next.error != null) {
        AppFunctions.showSnackBar(
          context: context,
          message: next.error.toString(),
        );
      }
    });

    ref.listen(connectionProvider, (previous, next) {
      print('the values is ${next.value}');
      if (!((next.value?.contains(ConnectivityResult.mobile) ?? false) ||
          (next.value?.contains(ConnectivityResult.wifi) ?? false) ||
          (next.value?.contains(ConnectivityResult.ethernet) ?? false))) {
        showAdaptiveDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return const AlertDialog(
              title: Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 50, color: Colors.red),
                  gapH12,
                  Text(
                    'Please check your internet connection and try again',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
        _isDialogOpen = true;
      } else {
        if (_isDialogOpen) {
          Navigator.of(context).pop();
          _isDialogOpen = false;
          // invalidate all other providers
          ref.invalidate(homeLiveAuctionsProvider);
          ref.invalidate(searchProductsProvider);
          ref.invalidate(getAllCategoriesProvider);
        }
      }
    });

    final authController = ref.watch(authControllerProvider);

    final bool isSignedIn = authController.valueOrNull != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).colorScheme.primary.brighten(20),
      ),
      child: Scaffold(
        // floatingActionButton: FloatingActionButton.extended(
        //     onPressed: () {}, label: Text('إضافة عرض')),
        appBar: AppBar(
          leadingWidth: _selectedIndex >= 1 ? 80 : 0,
          toolbarHeight: 75,
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
                      // image: authController.valueOrNull?.image,
                      name: authController.valueOrNull?.name,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👋 ${AppStrings.hi.tr()}, ${authController.valueOrNull?.name ?? 'User'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey, fontSize: 18),
                        ),
                        //Text(
                        //  authController.valueOrNull?.name ?? 'User',
                        //  style: Theme.of(context).textTheme.titleMedium
                        //      ?.copyWith(fontWeight: FontWeight.bold),
                        //),
                      ],
                    ),
                  ],
                )
              : null,
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 32),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    // Initialize notifications controller to start listening/fetching
                    ref.watch(notificationsNotifierProvider);
                    final unreadCount = ref.watch(unreadCountProvider);

                    if (unreadCount == 0) return const SizedBox.shrink();

                    return Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
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
                    );
                  },
                ),
              ],
            ),
            //if (isSignedIn)
            //  IconButton(
            //    icon: const Icon(Icons.logout),
            //    onPressed: () {
            //      ref.read(authControllerProvider.notifier).signOut();
            //    },
            //  ),
          ],
        ),
        extendBody: true, // Allows body to extend behind the floating navbar
        bottomNavigationBar: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Gradient drop shadow
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: const BoxDecoration(),
            ),
            // Floating Navigation Bar
            Container(
              margin: const EdgeInsets.only(),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                //gradient: LinearGradient(
                //  begin: Alignment.center,
                //  end: Alignment.topCenter,
                //  colors: [Colors.transparent, Color(0xFFDCCAA7)],
                //),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFDCCAA7),
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
                    setState(() {
                      _selectedIndex = index;
                      pageController.jumpToPage(index);
                    });
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
        ),
        body: SafeArea(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            children: const [
              HomeScreen(),
              AllAuctionsScreen(),
              StoreScreen(),
              OrdersListScreen(),
              MoreScreen(),
            ],
          ),
        ),
      ),
    );
  }
}

// page controller provider
final pageControllerProvider = Provider<PageController>((ref) {
  return PageController(initialPage: 0);
});

// stream provider for connection available
final connectionProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged;
});

class _UserAvatar extends StatelessWidget {
  final String? image;
  final String? name;

  const _UserAvatar({this.image, this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
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
          : null,
    );
  }
}
