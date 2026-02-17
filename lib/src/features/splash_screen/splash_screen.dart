import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/common_widgets/responsive_center.dart';
import '../../core/constants/app_images/app_images.dart';
import '../../core/constants/app_strings/app_strings.dart';
import '../../core/helper/cache/cached_variables.dart';
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
    // TODO: implement initState
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
                onEnd: () {
                  AuthRepository.getLocalDetails().then((_) {
                    if (!mounted) return;
                    log("[DEBUG] token: ${CachedVariables.token.toString()}");
                    log("[DEBUG] userId: ${CachedVariables.userId.toString()}");
                    log(
                      "[DEBUG] phone_number: ${CachedVariables.phone_number.toString()}",
                    );
                    log(
                      "[DEBUG] password: ${CachedVariables.password.toString()}",
                    );
                    if (CachedVariables.token != null &&
                        CachedVariables.userId != null) {
                      // Try to restore session using token and userId (Google Sign-In)
                      AuthRepository.getUser(CachedVariables.userId!)
                          .then((_) {
                            if (!mounted) return;
                            GoRouter.of(context).go(RouteConstants.home);
                          })
                          .catchError((error) {
                            if (!mounted) return;
                            // Fallback to phone/password if available, otherwise sign in
                            if (CachedVariables.phone_number != null &&
                                CachedVariables.password != null) {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .signIn(
                                    CachedVariables.phone_number!,
                                    CachedVariables.password!,
                                  );
                              //if (mounted) {
                              //  GoRouter.of(context).go(RouteConstants.home);
                              //}
                            }
                            //else {
                            //  if (mounted) {
                            //    GoRouter.of(context).go(RouteConstants.signIn);
                            //  }
                            //}
                          });
                    } else if (CachedVariables.phone_number != null &&
                        CachedVariables.password != null) {
                      // Fallback for old sessions or manual login without robust token support (if any)
                      ref
                          .read(authControllerProvider.notifier)
                          .signIn(
                            CachedVariables.phone_number!,
                            CachedVariables.password!,
                          );
                      //if (mounted) {
                      //  GoRouter.of(context).go(RouteConstants.home);
                      //}
                    }
                    //else {
                    //  if (mounted) {
                    //    GoRouter.of(context).go(RouteConstants.signIn);
                    //  }
                    //}
                    if (mounted) {
                      GoRouter.of(context).go(RouteConstants.home);
                    }
                  });
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
                            '\n${AppStrings.allRightsReserved.tr()} © ${DateTime.now().year}\n${AppStrings.version.tr()} 1.0.0',
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
