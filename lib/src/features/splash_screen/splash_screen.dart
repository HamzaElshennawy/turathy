import 'dart:async';

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
                    if (CachedVariables.phoneNumber != null &&
                        CachedVariables.password != null &&
                        CachedVariables.userId != null) {
                      ref
                          .read(authControllerProvider.notifier)
                          .signIn(
                            CachedVariables.phoneNumber!,
                            CachedVariables.password!,
                          );
                    }
                    GoRouter.of(context).go(RouteConstants.home);
                    // else {
                    //   GoRouter.of(context).go(RouteConstants.signIn);
                    // }
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
