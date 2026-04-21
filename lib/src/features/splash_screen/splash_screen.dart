/// {@category Navigation}
///
/// The initial loading screen that orchestrates the app's visual entrance.
///
/// [SplashScreen] provides an animated introduction (logo scale-up) and
/// determines whether to navigate the user to the main screen or
/// profile completion flow based on their authentication status.
import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/helper/analytics/analytics_service.dart';
import '../../core/common_widgets/responsive_center.dart';
import '../../core/constants/app_images/app_images.dart';
import '../../core/constants/app_strings/app_strings.dart';
import '../../core/helper/cache/cached_variables.dart';
import '../../core/helper/fcm/fcm_service.dart';
import '../../routing/rout_constants.dart';
import '../authintication/data/auth_repository.dart';
import '../authintication/presentation/auth_controller.dart';
import '../authintication/presentation/country_code_provider.dart';

/// The entry-point widget that handles initial app state and splash animations.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Controls the size of the logo for the scale-in animation.
  double logoScale = 0;
  double loadingTurns = 0;
  bool loadingVisibility = false;
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    // Auto-detect country code for the phone input fields early.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(countryCodeProvider.notifier).autoDetectCountry();
    });
    // Start scale animation after a short delay for smoothness.
    Timer(const Duration(milliseconds: 600), () {
      setState(() {
        logoScale = 1;
      });
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  String _currentAuthMethod() {
    if (CachedVariables.isGoogleSignIn) {
      return 'google';
    }
    if (CachedVariables.isAppleSignIn) {
      return 'apple';
    }
    return 'phone';
  }

  Future<bool> _restoreSessionFromTokens() async {
    final userId = CachedVariables.userId;
    if (userId == null) {
      return false;
    }

    try {
      final user = await AuthRepository.getUser(userId);
      if (!mounted) return true;

      await AnalyticsService.setUser(
        user,
        authMethod: _currentAuthMethod(),
      );
      ref.read(authControllerProvider.notifier).updateUser(user);
      await FCMService().registerAfterLogin();

      if (user.missingFields != null && user.missingFields!.isNotEmpty) {
        GoRouter.of(context).go(RouteConstants.completeProfile);
      }
      return true;
    } catch (error) {
      log('Direct session restore failed: $error');
    }

    if (CachedVariables.refreshToken == null || CachedVariables.refreshToken!.isEmpty) {
      return false;
    }

    try {
      final refreshed = await AuthRepository.refreshAccessToken();
      if (!refreshed) {
        return false;
      }

      final user = await AuthRepository.getUser(userId);
      if (!mounted) return true;

      await AnalyticsService.setUser(
        user,
        authMethod: _currentAuthMethod(),
      );
      ref.read(authControllerProvider.notifier).updateUser(user);
      await FCMService().registerAfterLogin();

      if (user.missingFields != null && user.missingFields!.isNotEmpty) {
        GoRouter.of(context).go(RouteConstants.completeProfile);
      }
      return true;
    } catch (error) {
      log('Refresh-token session restore failed: $error');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveCenter(
        child: Stack(
          children: [
            Center(
              child: AnimatedScale(
                /// Once the logo scaling animation completes, we transition to the app logic.
                onEnd: () async {
                  try {
                    // Attempt to load cached session details (tokens/IDs).
                    await AuthRepository.getLocalDetails();
                    if (!mounted) return;

                    log("[DEBUG] token: ${CachedVariables.token.toString()}");
                    log("[DEBUG] userId: ${CachedVariables.userId.toString()}");
                    log(
                      "[DEBUG] isGoogleSignIn: ${CachedVariables.isGoogleSignIn.toString()}",
                    );
                    log(
                      "[DEBUG] isAppleSignIn: ${CachedVariables.isAppleSignIn.toString()}",
                    );
                    log(
                      "[DEBUG] phone_number: ${CachedVariables.phone_number.toString()}",
                    );
                    log(
                      "[DEBUG] password: ${CachedVariables.password.toString()}",
                    );
                    final sessionRestored = await _restoreSessionFromTokens();
                    if (sessionRestored && !mounted) {
                      return;
                    }
                    if (sessionRestored) {
                      final authUser = ref.read(authControllerProvider).valueOrNull;
                      if (authUser != null &&
                          authUser.missingFields != null &&
                          authUser.missingFields!.isNotEmpty) {
                        return;
                      }
                    }

                    if (mounted) {
                      // Navigate to home; if auth failed, app will assume Guest state.
                      GoRouter.of(context).go(RouteConstants.home);
                    }
                  } catch (e) {
                    log("Fatal error in splash screen routing: $e");
                    if (mounted) {
                      GoRouter.of(context).go(RouteConstants.home);
                    }
                  }
                },
                duration: const Duration(seconds: 2),
                scale: logoScale,
                child: Image.asset(
                  AppImages.logo,
                  width: MediaQuery.of(context).size.width / 1.8,
                ),
              ),
            ),

            // Branding Footer
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: AppStrings.poweredBy.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      TextSpan(
                        text: AppStrings.turathyCo.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            '\n${AppStrings.allRightsReserved.tr()} © ${DateTime.now().year}\n${AppStrings.version.tr()} ${appVersion.isEmpty ? '...' : appVersion}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
