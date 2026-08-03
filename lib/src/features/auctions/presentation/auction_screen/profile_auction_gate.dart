import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/authintication/domain/user_model.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/complete_profile_screen.dart';

/// Returns true if the user can proceed to auction entry / bidding.
/// If profile is incomplete, navigates to [CompleteProfileScreen] and returns false.
Future<bool> ensureProfileCompleteForAuction(
  BuildContext context,
  WidgetRef ref, {
  Object? returnRouteArgs,
}) async {
  if (CachedVariables.userId == null) return true;

  UserModel? user = ref.read(authControllerProvider).valueOrNull;
  final missing = user?.missingFields ?? const <String>[];
  final incomplete =
      user?.isProfileComplete == false || missing.isNotEmpty;

  if (!incomplete) return true;

  if (!context.mounted) return false;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CompleteProfileScreen(
        highlightRequired: true,
        auctionEntryMode: true,
      ),
    ),
  );

  // Re-read after profile screen pops
  user = ref.read(authControllerProvider).valueOrNull;
  final stillMissing = user?.missingFields ?? const <String>[];
  return user?.isProfileComplete != false && stillMissing.isEmpty;
}

String profileIncompleteMessage() =>
    AppStrings.completeProfileToEnterAuction.tr();
