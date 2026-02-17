import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common_widgets/primary_button.dart';
import '../../../../core/common_widgets/responsive_center.dart';
import '../../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../../core/constants/app_images/app_images.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings/app_strings.dart';
import 'forgot_password_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String phone_number;

  const ResetPasswordScreen({super.key, required this.phone_number});

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
    // TODO: implement dispose
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // form with enter code and new password and confirm password
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
                          WhiteRoundedTextFormField(
                            controller: _codeController,
                            hintText: AppStrings.code.tr(),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return AppStrings.pleaseEnterTheCode.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          WhiteRoundedTextFormField(
                            controller: _newPasswordController,
                            hintText: AppStrings.newPassword.tr(),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return AppStrings.pleaseEnterTheNewPassword
                                    .tr();
                              }
                              return null;
                            },
                            keyboardType: TextInputType.visiblePassword,
                          ),
                          const SizedBox(height: 10),
                          WhiteRoundedTextFormField(
                            controller: _confirmPasswordController,
                            hintText: AppStrings.confirmPassword.tr(),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return AppStrings.pleaseEnterTheConfirmPassword
                                    .tr();
                              }
                              if (value != _newPasswordController.text) {
                                return AppStrings.passwordsDoNotMatch.tr();
                              }
                              return null;
                            },
                            keyboardType: TextInputType.visiblePassword,
                          ),
                          const SizedBox(height: 10),
                          PrimaryButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final ok = await ref
                                    .read(
                                      forgotPasswordControllerProvider.notifier,
                                    )
                                    .changePassword(
                                      e164Phone: widget.phone_number,
                                      otp: _codeController.text.trim(),
                                      password: _newPasswordController.text
                                          .trim(),
                                    );
                                if (!mounted) return;
                                if (ok) {
                                  // ignore: use_build_context_synchronously
                                  Navigator.of(
                                    // ignore: use_build_context_synchronously
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppStrings.resetPasswordSuccess.tr(),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            text: AppStrings.resetPassword.tr(),
                            isLoading: ref
                                .watch(forgotPasswordControllerProvider)
                                .isLoading,
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
