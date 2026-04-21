/// {@category Presentation}
///
/// Screen for verifying the reset OTP and setting a new account password.
/// 
/// This is the final step in the "Forgot Password" flow. The user must
/// provide the code received via SMS and a new, matching pair of passwords.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common_widgets/primary_button.dart';
import '../../../../core/common_widgets/responsive_center.dart';
import '../../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../../core/constants/app_images/app_images.dart';
import '../../../../core/constants/app_functions/app_functions.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings/app_strings.dart';
import '../../data/auth_repository.dart';
import 'forgot_password_controller.dart';

/// Screen where users enter the sent OTP and their new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  /// The phone number in E.164 format to which the code was sent.
  final String phone_number;
  final String challengeToken;

  const ResetPasswordScreen({
    super.key,
    required this.phone_number,
    required this.challengeToken,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(forgotPasswordControllerProvider, (previous, next) {
      if (next.hasError) {
        AppFunctions.showSnackBar(
          context: context,
          message: getFriendlyAuthMessage(next.error),
          isError: true,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.resetPassword.tr())),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.all(Sizes.p16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Image.asset(
                      AppImages.logo,
                      width: MediaQuery.of(context).size.width / 1.5,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            '${AppStrings.enterCodeAndPassword.tr()} (${widget.phone_number})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // OTP Code Input
                          WhiteRoundedTextFormField(
                            controller: _codeController,
                            hintText: AppStrings.code.tr(),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.pleaseEnterTheCode.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          
                          // New Password Input
                          WhiteRoundedTextFormField(
                            controller: _newPasswordController,
                            hintText: AppStrings.newPassword.tr(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.pleaseEnterTheNewPassword.tr();
                              }
                              return null;
                            },
                            keyboardType: TextInputType.visiblePassword,
                          ),
                          const SizedBox(height: 10),
                          
                          // Confirm Password Input with matching check
                          WhiteRoundedTextFormField(
                            controller: _confirmPasswordController,
                            hintText: AppStrings.confirmPassword.tr(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.pleaseEnterTheConfirmPassword.tr();
                              }
                              if (value != _newPasswordController.text) {
                                return AppStrings.passwordsDoNotMatch.tr();
                              }
                              return null;
                            },
                            keyboardType: TextInputType.visiblePassword,
                          ),
                          const SizedBox(height: 10),
                          
                          // Submission Button
                          PrimaryButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final ok = await ref
                                    .read(forgotPasswordControllerProvider.notifier)
                                    .changePassword(
                                      challengeToken: widget.challengeToken,
                                      otp: _codeController.text.trim(),
                                      password: _newPasswordController.text.trim(),
                                    );
                                
                                if (!mounted) return;
                                
                                if (ok) {
                                  // Go back to the login screen and show success message.
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                  AppFunctions.showSnackBar(
                                    context: context,
                                    message: AppStrings.resetPasswordSuccess.tr(),
                                  );
                                }
                              }
                            },
                            text: AppStrings.resetPassword.tr(),
                            isLoading: ref.watch(forgotPasswordControllerProvider).isLoading,
                          ),
                        ],
                      ),
                    ),
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
