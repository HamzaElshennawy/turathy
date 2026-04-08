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

import '../../core/helper/analytics/analytics_service.dart';
import '../../core/common_widgets/responsive_center.dart';
import '../../core/constants/app_images/app_images.dart';
import '../../core/constants/app_strings/app_strings.dart';
import '../../core/helper/cache/cached_variables.dart';
import '../../core/helper/fcm/fcm_service.dart';
import '../../routing/rout_constants.dart';
import '../authintication/data/auth_repository.dart';
import '../authintication/data/google_sign_in_client.dart';
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

  @override
  void initState() {
    super.initState();
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
                      "[DEBUG] phone_number: ${CachedVariables.phone_number.toString()}",
                    );
                    log(
                      "[DEBUG] password: ${CachedVariables.password.toString()}",
                    );
                    if (CachedVariables.token != null &&
                        CachedVariables.userId != null) {
                      try {
                        final user = await AuthRepository.getUser(
                          CachedVariables.userId!,
                        );
                        if (!mounted) return;

                        await AnalyticsService.setUser(
                          user,
                          authMethod: CachedVariables.isGoogleSignIn
                              ? 'google'
                              : 'phone',
                        );
                        ref
                            .read(authControllerProvider.notifier)
                            .updateUser(user);

                        // If user is logged in but has missing required fields, send them to complete profile.
                        if (user.missingFields != null &&
                            user.missingFields!.isNotEmpty) {
                          GoRouter.of(
                            context,
                          ).go(RouteConstants.completeProfile);
                          return;
                        }
                      } catch (error) {
                        log(
                          "Session restore failed, checking fallback: $error",
                        );
                        if (!mounted) return;

                        // Fallback 1: Silent Google Re-authentication
                        if (CachedVariables.isGoogleSignIn) {
                          try {
                            final googleSignIn = buildGoogleSignInClient();
                            final googleUser = await googleSignIn
                                .signInSilently();
                            if (googleUser != null) {
                              final googleAuth =
                                  await googleUser.authentication;
                              final idToken = googleAuth.idToken;
                              if (idToken != null) {
                                final user = await AuthRepository.googleSignIn(
                                  idToken,
                                );
                                if (!mounted) return;
                                await AnalyticsService.setUser(
                                  user,
                                  authMethod: 'google',
                                );
                                ref
                                    .read(authControllerProvider.notifier)
                                    .updateUser(user);
                                await FCMService().registerAfterLogin();
                              }
                            }
                          } catch (googleError) {
                            log("Google silent sign-in failed: $googleError");
                          }
                        }
                        // Fallback 2: Stored Credential Re-login
                        else if (CachedVariables.phone_number != null &&
                            CachedVariables.password != null) {
                          final result = await ref
                              .read(authControllerProvider.notifier)
                              .signIn(
                                CachedVariables.phone_number!,
                                CachedVariables.password!,
                              );

                          if (result['status'] != 'error') {
                            final authUser = ref
                                .read(authControllerProvider)
                                .valueOrNull;
                            if (authUser != null &&
                                authUser.missingFields != null &&
                                authUser.missingFields!.isNotEmpty) {
                              if (mounted) {
                                GoRouter.of(
                                  context,
                                ).go(RouteConstants.completeProfile);
                              }
                              return;
                            }
                          }
                        }
                      }
                    }
                    // Case for Google users whose token might have expired but session remains valid.
                    else if (CachedVariables.isGoogleSignIn &&
                        CachedVariables.userId != null) {
                      try {
                        final googleSignIn = buildGoogleSignInClient();
                        final googleUser = await googleSignIn.signInSilently();
                        if (googleUser != null) {
                          final googleAuth = await googleUser.authentication;
                          final idToken = googleAuth.idToken;
                          if (idToken != null) {
                            final user = await AuthRepository.googleSignIn(
                              idToken,
                            );
                            if (!mounted) return;
                            await AnalyticsService.setUser(
                              user,
                              authMethod: 'google',
                            );
                            ref
                                .read(authControllerProvider.notifier)
                                .updateUser(user);
                            await FCMService().registerAfterLogin();
                          }
                        }
                      } catch (googleError) {
                        log("Google silent sign-in failed: $googleError");
                      }
                    }
                    // Final attempt: explicit sign-in if credentials exist.
                    else if (CachedVariables.phone_number != null &&
                        CachedVariables.password != null) {
                      final result = await ref
                          .read(authControllerProvider.notifier)
                          .signIn(
                            CachedVariables.phone_number!,
                            CachedVariables.password!,
                          );

                      if (result['status'] != 'error') {
                        final authUser = ref
                            .read(authControllerProvider)
                            .valueOrNull;
                        if (authUser != null &&
                            authUser.missingFields != null &&
                            authUser.missingFields!.isNotEmpty) {
                          if (mounted) {
                            GoRouter.of(
                              context,
                            ).go(RouteConstants.completeProfile);
                          }
                          return;
                        }
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
                            '\n${AppStrings.allRightsReserved.tr()} © ${DateTime.now().year}\n${AppStrings.version.tr()} 0.1.0',
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
