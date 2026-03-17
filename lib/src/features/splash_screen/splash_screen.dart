import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/common_widgets/responsive_center.dart';
import '../../core/constants/app_images/app_images.dart';
import '../../core/constants/app_strings/app_strings.dart';
import '../../core/helper/cache/cached_variables.dart';
import '../../core/helper/fcm/fcm_service.dart';
import '../../routing/rout_constants.dart';
import '../authintication/data/auth_repository.dart';
import '../authintication/presentation/auth_controller.dart';
import '../authintication/presentation/country_code_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double logoScale = 0;
  double loadingTurns = 0;
  bool loadingVisibility = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(countryCodeProvider.notifier).autoDetectCountry();
    });
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
                onEnd: () async {
                  try {
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
                        // Try to restore session
                        final user = await AuthRepository.getUser(
                          CachedVariables.userId!,
                        );
                        if (!mounted) return;

                        // Update auth controller state safely
                        ref
                            .read(authControllerProvider.notifier)
                            .updateUser(user);

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

                        // Fallback 1: Google silent sign-in (for Google SSO users)
                        if (CachedVariables.isGoogleSignIn) {
                          try {
                            log("Attempting Google silent sign-in...");
                            final googleSignIn = GoogleSignIn();
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
                        // Fallback 2: phone/password re-login
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
                    } else if (CachedVariables.isGoogleSignIn &&
                        CachedVariables.userId != null) {
                      // Token is null but user previously signed in with Google — attempt silent re-auth
                      log(
                        "Token null for Google user, attempting silent sign-in...",
                      );
                      try {
                        final googleSignIn = GoogleSignIn();
                        final googleUser = await googleSignIn.signInSilently();
                        if (googleUser != null) {
                          final googleAuth = await googleUser.authentication;
                          final idToken = googleAuth.idToken;
                          if (idToken != null) {
                            final user = await AuthRepository.googleSignIn(
                              idToken,
                            );
                            if (!mounted) return;
                            ref
                                .read(authControllerProvider.notifier)
                                .updateUser(user);
                            await FCMService().registerAfterLogin();
                          }
                        }
                      } catch (googleError) {
                        log("Google silent sign-in failed: $googleError");
                      }
                    } else if (CachedVariables.phone_number != null &&
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
                      // Navigate to home regardless of auth state (will act as guest if not authenticated)
                      GoRouter.of(context).go(RouteConstants.home);
                    }
                  } catch (e) {
                    log("Fatal error in splash screen routing: $e");
                    // On complete failure (e.g. no network), just go to home so app doesn't freeze
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
