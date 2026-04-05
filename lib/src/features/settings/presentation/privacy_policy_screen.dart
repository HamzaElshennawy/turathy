import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    final sections = [
      _PolicySection(
        AppStrings.privacy1Title.tr(),
        AppStrings.privacy1Content.tr(),
        Icons.info_outline_rounded,
      ),
      _PolicySection(
        AppStrings.privacy2Title.tr(),
        AppStrings.privacy2Content.tr(),
        Icons.data_usage_rounded,
      ),
      _PolicySection(
        AppStrings.privacy3Title.tr(),
        AppStrings.privacy3Content.tr(),
        Icons.insights_rounded,
      ),
      _PolicySection(
        AppStrings.privacy4Title.tr(),
        AppStrings.privacy4Content.tr(),
        Icons.share_rounded,
      ),
      _PolicySection(
        AppStrings.privacy5Title.tr(),
        AppStrings.privacy5Content.tr(),
        Icons.security_rounded,
      ),
      _PolicySection(
        AppStrings.privacy6Title.tr(),
        AppStrings.privacy6Content.tr(),
        Icons.verified_user_rounded,
      ),
      _PolicySection(
        AppStrings.privacy7Title.tr(),
        AppStrings.privacy7Content.tr(),
        Icons.history_rounded,
      ),
      _PolicySection(
        AppStrings.privacy8Title.tr(),
        AppStrings.privacy8Content.tr(),
        Icons.cookie_rounded,
      ),
      _PolicySection(
        AppStrings.privacy9Title.tr(),
        AppStrings.privacy9Content.tr(),
        Icons.contact_support_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            leading: const BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                AppStrings.privacyPolicy.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              background: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        size: 48,
                        color: themeColor,
                      ),
                    ),
                    gapH4,
                    Text(
                      AppStrings.legalInformation.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 32), // Space for titled title
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildPolicyCard(
                    context,
                    sections[index],
                    themeColor,
                    index,
                  );
                },
                childCount: sections.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: gapH32),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context,
    _PolicySection section,
    Color themeColor,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                section.icon,
                color: themeColor,
                size: 24,
              ),
            ),
            gapW16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  gapH8,
                  Text(
                    section.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  final String title;
  final String content;
  final IconData icon;

  _PolicySection(this.title, this.content, this.icon);
}
