import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/common_widgets/primary_button.dart';
import '../../../core/constants/app_icons/app_icons.dart';
import '../../../core/constants/app_lottie/app_lottie.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../authintication/presentation/auth_controller.dart';
import '../../authintication/presentation/sign_in_screen.dart';
import '../../main_screen.dart';
import '../controller/theme_controller.dart';
import 'widgets/language_widget/language_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final state = ref.watch(profileScreenControllerProvider);
    final data = ref.watch(authControllerProvider).valueOrNull;
    final theme = ref.watch(themeControllerProvider);
    double iconSize = 60;
    final bool isSignedIn =
        ref.watch(authControllerProvider).valueOrNull != null;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.profileAndSettings.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          gapH8,
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(Sizes.p8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: Lottie.asset(
                        AppLottie.settings,
                        fit: BoxFit.contain,
                        height: MediaQuery.of(context).size.height / 3,
                      ),
                    ),
                    Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(AppStrings.changeTheme.tr()),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
// Theme selection dropdown removed as per user request
                                    gapH8,
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(AppStrings.darkMode.tr()),
                                        Switch.adaptive(
                                          value: theme.mode == ThemeMode.dark,
                                          onChanged: (value) {
                                            if (value) {
                                              ref
                                                  .read(themeControllerProvider
                                                      .notifier)
                                                  .setTheme(theme.copyWith(
                                                      mode: ThemeMode.dark));
                                            } else {
                                              ref
                                                  .read(themeControllerProvider
                                                      .notifier)
                                                  .setTheme(theme.copyWith(
                                                      mode: ThemeMode.light));
                                            }
                                          },
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        // language
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.changeLanguage.tr()),
                            Card(
                              child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(8),
                                  width: double.infinity,
                                  child: const LanguageWidget()),
                            ),
                          ],
                        ),
                        gapH8,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppStrings.userDetails.tr()),
                                // TextButton.icon(
                                //     onPressed: () {
                                //       // todo : open dialog to edit profile and handle picture
                                //     },
                                //     icon: const Icon(Icons.edit_note),
                                //     label: Text(AppStrings.editProfile.tr()))
                              ],
                            ),
                            Card(
                              // color: Theme.of(context).cardColor,

                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: isSignedIn
                                    ? Column(
                                        children: [
                                          if (data != null)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            '${AppStrings.name.tr()} : ',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium,
                                                          ),
                                                          Text(
                                                            '${data.name}',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium,
                                                          ),
                                                        ],
                                                      ),
                                                      Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            '${AppStrings.phone.tr()} : ',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium,
                                                          ),
                                                          Text(
                                                            data.phoneNumber!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          gapH16,
                                          Row(
                                            children: [
                                              Expanded(
                                                child: PrimaryButton(
                                                  onPressed: () async {
                                                    final result =
                                                        await showDialog(
                                                      context: context,
                                                      // sign out dialog
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: Text(AppStrings
                                                            .signOut
                                                            .tr()),
                                                        content: Text(AppStrings
                                                            .areYouSureToSignOut
                                                            .tr()),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: Text(
                                                                AppStrings
                                                                    .cancel
                                                                    .tr()),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true);
                                                            },
                                                            child: Text(
                                                                AppStrings
                                                                    .signOut
                                                                    .tr()),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (result == true) {
                                                      // todo : sign out
                                                      ref
                                                          .read(
                                                              pageControllerProvider)
                                                          .jumpToPage(0);
                                                      ref
                                                          .read(
                                                              authControllerProvider
                                                                  .notifier)
                                                          .signOut()
                                                          .then(
                                                        (value) {
                                                          print(
                                                              'value : $value');
                                                          if (value &&
                                                              context.mounted) {
                                                            Navigator.of(
                                                                    context)
                                                                .push(
                                                                    MaterialPageRoute(
                                                              builder: (context) =>
                                                                  SignInScreen(),
                                                            ));
                                                          }
                                                        },
                                                      );
                                                    }
                                                  },
                                                  isLoading: false,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                  text: AppStrings.signOut.tr(),
                                                  svgPath: AppIcons.signOut,
                                                ),
                                              ),
                                              gapW16,
                                              Expanded(
                                                child: PrimaryButton(
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                            content: Text(AppStrings
                                                                .holdPressToDeleteAccount
                                                                .tr())));
                                                  },
                                                  onLongPress: () async {
                                                    final result =
                                                        await showDialog(
                                                      context: context,
                                                      // delete account dialog
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: Text(
                                                          AppStrings
                                                              .deleteAccount
                                                              .tr(),
                                                        ),
                                                        content: Text(
                                                          AppStrings
                                                              .areYouSureToDeleteAccount
                                                              .tr(),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: Text(
                                                                AppStrings
                                                                    .cancel
                                                                    .tr()),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true);
                                                            },
                                                            child: Text(
                                                                AppStrings
                                                                    .delete
                                                                    .tr()),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (result == true) {
                                                      // todo : delete account
                                                      ref
                                                          .read(
                                                              pageControllerProvider)
                                                          .jumpToPage(0);
                                                    }
                                                  },
                                                  isLoading: false,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                  text: AppStrings.deleteAccount
                                                      .tr(),
                                                  svgPath:
                                                      AppIcons.deleteAccount,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Text(
                                            AppStrings
                                                .pleaseSignInOrCreateAccount
                                                .tr(),
                                          ),
                                          gapH8,
                                          PrimaryButton(
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          SignInScreen()));
                                            },
                                            text: AppStrings.signIn.tr(),
                                            isLoading: false,
                                          ),
                                        ],
                                      ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.contactUs.tr(),
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 12),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceEvenly,
                                        children: [
                                          InkWell(
                                            onTap: () {},
                                            child: Image.asset(
                                              'assets/icons/facebook.png',
                                              fit: BoxFit.contain,
                                              width: iconSize,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {},
                                            child: Image.asset(
                                              'assets/icons/insta.png',
                                              fit: BoxFit.contain,
                                              width: iconSize,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {},
                                            child: Image.asset(
                                              'assets/icons/tiktok.png',
                                              fit: BoxFit.contain,
                                              width: iconSize,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {},
                                            child: Image.asset(
                                              'assets/icons/whats.png',
                                              fit: BoxFit.contain,
                                              width: iconSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.legalInformation.tr(),
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Wrap(
                                    direction: Axis.vertical,
                                    alignment: WrapAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: () {},
                                        child:
                                            Text(AppStrings.privacyPolicy.tr()),
                                      ),
                                      gapH8,
                                      InkWell(
                                        onTap: () {},
                                        child: Text(
                                            AppStrings.termsAndConditions.tr()),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                            '${AppStrings.version.tr()} : ${ref.watch(versionProvider).value}'),
                        gapH12,
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final versionProvider = FutureProvider<String>((ref) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String version = packageInfo.version;

  return version;
});
