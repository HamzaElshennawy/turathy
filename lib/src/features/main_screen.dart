import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_images/app_images.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';

import '../core/constants/app_functions/app_functions.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_strings/app_strings.dart';
import 'auctions/data/auctions_repository.dart';
import 'auctions/presentation/auction_screen/user_auctions_screen.dart';
import 'authintication/presentation/auth_controller.dart';
import 'home/data/category_repository.dart';
import 'home/presentation/home_screen/home_screen.dart';
import 'profile/presentation/profile_screen.dart';
import 'search/presentation/search_screen.dart';

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
          ref.invalidate(liveAuctionsProvider);
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
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(AppImages.logo),
          ),
          title: Text(
            AppStrings.appName.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(AppStrings.changeLanguage.tr()),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('English'),
                            onTap: () {
                              context.setLocale(const Locale('en'));
                              Navigator.of(context).pop();
                            },
                          ),
                          ListTile(
                            title: const Text('العربية'),
                            onTap: () {
                              context.setLocale(const Locale('ar'));
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            if (isSignedIn)
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 60,
          elevation: 3,
          shadowColor: Theme.of(context).colorScheme.shadow.withAlpha(100),
          backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(98),
          surfaceTintColor: Theme.of(context).colorScheme.primary.withAlpha(3),
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
              icon: const Icon(Icons.home_outlined, size: 22),
              selectedIcon: const Icon(Icons.home, size: 22),
              label: AppStrings.home.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.manage_search_outlined, size: 22),
              selectedIcon: const Icon(Icons.manage_search, size: 22),
              label: AppStrings.search.tr(),
            ),
            if (isSignedIn)
              NavigationDestination(
                icon: const Icon(Icons.gavel_outlined, size: 22),
                selectedIcon: const Icon(Icons.gavel, size: 22),
                label: AppStrings.myAuctions.tr(),
              ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline, size: 22),
              selectedIcon: const Icon(Icons.person, size: 22),
              label: AppStrings.profile.tr(),
            ),
          ],
        ),
        body: SafeArea(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            children: [
              const HomeScreen(),
              const SearchScreen(),
              if (isSignedIn) const UserAuctionsScreen(),
              const ProfileScreen(),
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
