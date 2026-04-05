import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/common_widgets/primary_button.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../authintication/presentation/auth_controller.dart';
import '../../authintication/presentation/complete_profile_screen.dart';
import '../../authintication/presentation/sign_in_screen.dart';
import '../../auctions/presentation/auction_screen/my_auction_requests_screen.dart';
// import '../../main_screen.dart';
import '../controller/theme_controller.dart';
// import 'widgets/language_widget/language_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final theme = ref.watch(themeControllerProvider);
    final bool isSignedIn = user != null;
    final themeColor = Theme.of(context).primaryColor;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppStrings.profile.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: isTablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderSection(
                          context,
                          user,
                          isSignedIn,
                          themeColor,
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.grey.shade300),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          gapH24,
                          ..._buildRightSections(
                            context,
                            ref,
                            isSignedIn,
                            theme,
                            themeColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderSection(context, user, isSignedIn, themeColor),
                  gapH24,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildRightSections(
                        context,
                        ref,
                        isSignedIn,
                        theme,
                        themeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    dynamic user,
    bool isSignedIn,
    Color themeColor,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: themeColor.withOpacity(0.1),
            child: isSignedIn
                ? Text(
                    user.name?.isNotEmpty == true
                        ? user.name!.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  )
                : Icon(Icons.person, size: 50, color: themeColor),
          ),
          gapH16,
          if (isSignedIn) ...[
            Text(
              user.name ?? AppStrings.name.tr(),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            gapH4,
            Text(
              user.phone_number ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ] else ...[
            Text(
              AppStrings.pleaseSignInOrCreateAccount.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
            ),
            gapH16,
            PrimaryButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen()),
                );
              },
              text: AppStrings.signIn.tr(),
              isLoading: false,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRightSections(
    BuildContext context,
    WidgetRef ref,
    bool isSignedIn,
    dynamic theme,
    Color themeColor,
  ) {
    return [
      // --- Account Section ---
      if (isSignedIn) ...[
        _buildSectionTitle(AppStrings.account.tr(), context),
        _buildSettingsGroup([
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: AppStrings.userDetails.tr(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompleteProfileScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.assignment_ind_outlined,
            title: AppStrings.myAuctionRequests.tr(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyAuctionRequestsScreen(),
                ),
              );
            },
          ),
        ]),
        gapH24,
      ],



      // --- Danger Zone ---
      if (isSignedIn) ...[
        _buildSectionTitle(AppStrings.dangerZone.tr(), context),
        _buildSettingsGroup([
          _buildSettingsTile(
            icon: Icons.logout_outlined,
            title: AppStrings.signOut.tr(),
            textColor: Colors.red.shade600,
            iconColor: Colors.red.shade600,
            onTap: () => _handleSignOut(context, ref),
          ),
          //_buildSettingsTile(
          //  icon: Icons.person_remove_outlined,
          //  title: AppStrings.deleteAccount.tr(),
          //  textColor: Colors.red.shade600,
          //  iconColor: Colors.red.shade600,
          //  onTap: () => _handleDeleteAccount(context, ref),
          //),
        ]),
      ],


    ];
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final int idx = entry.key;
          final Widget child = entry.value;
          if (idx == children.length - 1) {
            return child;
          }
          return Column(
            children: [
              child,
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade100,
                indent: 56,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF2D4739)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF2D4739),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
          fontSize: 15,
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20)
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }



  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.signOut.tr()),
        content: Text(AppStrings.areYouSureToSignOut.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.signOut.tr()),
          ),
        ],
      ),
    );

    if (result == true) {
      ref.read(authControllerProvider.notifier).signOut().then((value) {
        if (value && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => SignInScreen()),
            (route) => false,
          );
        }
      });
    }
  }

  //Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
  //  final result = await showDialog<bool>(
  //    context: context,
  //    builder: (context) => AlertDialog(
  //      title: Text(AppStrings.deleteAccount.tr()),
  //      content: Text(AppStrings.areYouSureToDeleteAccount.tr()),
  //      actions: [
  //        TextButton(
  //          onPressed: () => Navigator.of(context).pop(false),
  //          child: Text(AppStrings.cancel.tr()),
  //        ),
  //        TextButton(
  //          onPressed: () => Navigator.of(context).pop(true),
  //          style: TextButton.styleFrom(foregroundColor: Colors.red),
  //          child: Text(AppStrings.delete.tr()),
  //        ),
  //      ],
  //    ),
  //  );

  //  if (result == true) {
  //    // TODO: Handle delete account API call
  //  }
  //}
}


