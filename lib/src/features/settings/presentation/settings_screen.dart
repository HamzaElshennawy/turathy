import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/analytics/analytics_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../profile/presentation/widgets/language_widget/language_widget.dart';
import 'terms_and_conditions_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'settings_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppStrings.settings.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Preferences Section ---
              _buildSectionTitle(AppStrings.preferences.tr(), context),
              _buildSettingsGroup([
                _buildSettingsTile(
                  icon: Icons.language_outlined,
                  title: AppStrings.changeLanguage.tr(),
                  trailing: const LanguageWidget(),
                ),
              ]),
              gapH24,

              // --- Support & Legal Section ---
              _buildSectionTitle(AppStrings.supportAndLegal.tr(), context),
              _buildSettingsGroup([
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: AppStrings.privacyPolicy.tr(),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.description_outlined,
                  title: AppStrings.termsAndConditions.tr(),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsScreen(),
                      ),
                    );
                  },
                ),
              ]),
              gapH24,

              // --- Contact Us Section ---
              _buildSectionTitle(AppStrings.contactUs.tr(), context),
              _buildSettingsGroup([
                _buildSettingsTile(
                  icon: Icons.chat_outlined,
                  title: AppStrings.whatsApp.tr(),
                  onTap: () async {
                    final whatsappUri = Uri.parse("https://wa.me/966580545085");
                    if (await canLaunchUrl(whatsappUri)) {
                      await launchUrl(
                        whatsappUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("WhatsApp is not installed"),
                          ),
                        );
                      }
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      gapW8,
                      _buildSocialIcon('assets/icons/whats.png', () async {
                        final whatsappUri = Uri.parse(
                          "https://wa.me/966580545085",
                        );
                        if (await canLaunchUrl(whatsappUri)) {
                          await launchUrl(
                            whatsappUri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("WhatsApp is not installed"),
                              ),
                            );
                          }
                        }
                      }),
                    ],
                  ),
                ),
                _buildSettingsTile(
                  icon: Icons.phone_outlined,
                  title: AppStrings.call.tr(),
                  onTap: () async {
                    final callUri = Uri.parse("tel:+966580545085");
                    if (await canLaunchUrl(callUri)) {
                      await launchUrl(callUri);
                    }
                  },
                ),
              ]),
              gapH32,

              // --- Version Information ---
              Center(
                child: Text(
                  '${AppStrings.version.tr()} : ${ref.watch(settingsVersionProvider).value ?? ""}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
              gapH32,
            ],
          ),
        ),
      ),
    );
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

  Widget _buildSocialIcon(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(assetPath, width: 32, height: 32, fit: BoxFit.contain),
    );
  }
}

final settingsVersionProvider = FutureProvider<String>((ref) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return '${packageInfo.version} (${packageInfo.buildNumber})';
});





