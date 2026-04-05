import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/sign_in_screen.dart';
import 'package:turathy/src/features/favorites/presentation/likes_screen.dart';
import 'package:turathy/src/features/profile/presentation/profile_screen.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/my_payments_screen.dart';
import 'package:turathy/src/features/settings/presentation/settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authControllerProvider);
    final user = userState.valueOrNull;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppStrings.profile.tr()), // "My Account" / حسابي
      ),
      body: isTablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        ..._buildProfileSection(context, user),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.grey.shade300),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        ..._buildMenuItems(context, ref, user),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  ..._buildProfileSection(context, user),
                  const SizedBox(height: 10),
                  ..._buildMenuItems(context, ref, user),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildProfileSection(BuildContext context, dynamic user) {
    if (user != null) {
      return [
        const CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(
            'https://placehold.co/200',
          ), // Placeholder or user image
          // child: user.image == null ? Icon(Icons.person, size: 50) : null,
        ),
        const SizedBox(height: 10),
        Text(
          user.name ?? '',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          user.phone_number ?? '', // Or email if available
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ];
    } else {
      return [
        const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 10),
        Text(
          AppStrings.pleaseSignInOrCreateAccount.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => SignInScreen()));
          },
          child: Text(AppStrings.signIn.tr()),
        ),
      ];
    }
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    return [
      if (user != null) ...[
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(AppStrings.profile.tr()),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
      ],
      ListTile(
        leading: const Icon(Icons.settings_outlined),
        title: Text(AppStrings.settings.tr()),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
      ),
      //  leading: const Icon(Icons.settings),
      //  title: Text(AppStrings.settings.tr()),
      //  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      //  onTap: () {
      //    _showLanguageDialog(context);
      //  },
      //),
      //const Divider(),
      //ListTile(
      //  leading: const Icon(Icons.calendar_month),
      //  title: Text(AppStrings.auctions.tr()),
      //  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      //  onTap: () {
      //    // TODO: Navigate to Auctions History or similar
      //  },
      //),
      //    // TODO: Navigate to Products
      //  },
      //),
      ListTile(
        leading: const Icon(Icons.favorite),
        title: Text(AppStrings.likes.tr()),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const LikesScreen()));
        },
      ),
      ListTile(
        leading: const Icon(Icons.history),
        title: Text(AppStrings.myPayments.tr()),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MyPaymentsScreen()),
          );
        },
      ),
      //ListTile(
      //  leading: const Icon(Icons.dashboard_customize_outlined),
      //  title: Text(AppStrings.hostDashboard.tr()),
      //  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      //  onTap: () {
      //    Navigator.of(context).push(
      //      MaterialPageRoute(
      //        builder: (context) => const MyItemsScreen(),
      //      ),
      //    );
      //  },
      //),
      //const Divider(),
      //if (user != null)
      //  ListTile(
      //    leading: const Icon(Icons.logout, color: Colors.red),
      //    title: Text(
      //      AppStrings.signOut.tr(),
      //      style: const TextStyle(color: Colors.red),
      //    ),
      //    trailing: const Icon(
      //      Icons.arrow_forward_ios,
      //      size: 16,
      //      color: Colors.red,
      //    ),
      //    onTap: () {
      //      showDialog(
      //        context: context,
      //        builder: (ctx) => AlertDialog(
      //          title: Text(AppStrings.signOut.tr()),
      //          content: Text(AppStrings.areYouSureToSignOut.tr()),
      //          actions: [
      //            TextButton(
      //              onPressed: () => Navigator.of(ctx).pop(),
      //              child: Text(
      //                AppStrings.cancel.tr(),
      //                style: const TextStyle(color: Colors.grey),
      //              ),
      //            ),
      //            TextButton(
      //              onPressed: () {
      //                Navigator.of(ctx).pop();
      //                ref.read(authControllerProvider.notifier).signOut();
      //              },
      //              child: Text(
      //                AppStrings.signOut.tr(),
      //                style: const TextStyle(color: Colors.red),
      //              ),
      //            ),
      //          ],
      //        ),
      //      );
      //    },
      //  ),
      //if (user != null) const Divider(),
    ];
  }

  //void _showLanguageDialog(BuildContext context) {
  //  showDialog(
  //    context: context,
  //    builder: (context) {
  //      return AlertDialog(
  //        title: Text(AppStrings.changeLanguage.tr()),
  //        content: Column(
  //          mainAxisSize: MainAxisSize.min,
  //          children: [
  //            ListTile(
  //              title: const Text('English'),
  //              trailing: context.locale.languageCode == 'en'
  //                  ? const Icon(Icons.check, color: Colors.green)
  //                  : null,
  //              onTap: () {
  //                context.setLocale(const Locale('en'));
  //                Navigator.of(context).pop();
  //              },
  //            ),
  //            ListTile(
  //              title: const Text('العربية'),
  //              trailing: context.locale.languageCode == 'ar'
  //                  ? const Icon(Icons.check, color: Colors.green)
  //                  : null,
  //              onTap: () {
  //                context.setLocale(const Locale('ar'));
  //                Navigator.of(context).pop();
  //              },
  //            ),
  //          ],
  //        ),
  //      );
  //    },
  //  );
  //}
}
