import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    final sections = [
      _TermSection(
        AppStrings.terms1Title.tr(),
        AppStrings.terms1Content.tr(),
        Icons.info_outline_rounded,
      ),
      _TermSection(
        AppStrings.terms2Title.tr(),
        AppStrings.terms2Content.tr(),
        Icons.book_rounded,
      ),
      _TermSection(
        AppStrings.terms3Title.tr(),
        AppStrings.terms3Content.tr(),
        Icons.gavel_rounded,
      ),
      _TermSection(
        AppStrings.terms4Title.tr(),
        AppStrings.terms4Content.tr(),
        Icons.person_search_rounded,
      ),
      _TermSection(
        AppStrings.terms5Title.tr(),
        AppStrings.terms5Content.tr(),
        Icons.rule_rounded,
      ),
      _TermSection(
        AppStrings.terms6Title.tr(),
        AppStrings.terms6Content.tr(),
        Icons.account_balance_wallet_rounded,
      ),
      _TermSection(
        AppStrings.terms7Title.tr(),
        AppStrings.terms7Content.tr(),
        Icons.payments_rounded,
      ),
      _TermSection(
        AppStrings.terms8Title.tr(),
        AppStrings.terms8Content.tr(),
        Icons.assignment_ind_rounded,
      ),
      _TermSection(
        AppStrings.terms9Title.tr(),
        AppStrings.terms9Content.tr(),
        Icons.lock_rounded,
      ),
      _TermSection(
        AppStrings.terms10Title.tr(),
        AppStrings.terms10Content.tr(),
        Icons.warning_amber_rounded,
      ),
      _TermSection(
        AppStrings.terms11Title.tr(),
        AppStrings.terms11Content.tr(),
        Icons.policy_rounded,
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
                AppStrings.termsAndConditions.tr(),
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
                        Icons.gavel_rounded,
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
                  return _buildTermCard(
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

  Widget _buildTermCard(
    BuildContext context,
    _TermSection section,
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

class _TermSection {
  final String title;
  final String content;
  final IconData icon;

  _TermSection(this.title, this.content, this.icon);
}
