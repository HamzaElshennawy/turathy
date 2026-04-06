/// {@category Presentation}
///
/// Starting screen for the "Forgot Password" flow.
/// 
/// This screen prompts the user to enter their registered phone number
/// (currently limited to KSA +966) to receive a password reset code.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;

import '../../../../core/common_widgets/primary_button.dart';
import '../../../../core/common_widgets/responsive_center.dart';
import '../../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../../core/constants/app_images/app_images.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings/app_strings.dart';
import '../../../../utils/validators.dart';
import 'reset_password_screen.dart';
import 'forgot_password_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for entering the phone number to initiate password reset.
class InputEmailForgotPasswordScreen extends ConsumerStatefulWidget {
  const InputEmailForgotPasswordScreen({super.key});

  @override
  ConsumerState<InputEmailForgotPasswordScreen> createState() =>
      _InputEmailForgotPasswordScreenState();
}

class _InputEmailForgotPasswordScreenState
    extends ConsumerState<InputEmailForgotPasswordScreen> {
  final TextEditingController _phoneLocalController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneLocalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    // Visual Branding
                    Image.asset(
                      AppImages.logo,
                      width: MediaQuery.of(context).size.width / 1.5,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            AppStrings.enterYourPhoneToResetPassword.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // Phone Input with fixed KSA prefix.
                          // Using LTR directionality for the number field.
                          Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: WhiteRoundedTextFormField(
                              hintText: '5XXXXXXXX',
                              prefixIcon: const Icon(Icons.phone),
                              controller: _phoneLocalController,
                              validator: Validators.ksaLocalPhoneValidator,
                              inputFormatters: Validators.ksaLocalPhoneInputFormatters,
                              keyboardType: TextInputType.phone,
                              prefix: '+966',
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // Action Button
                          PrimaryButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final e164 = '+966${_phoneLocalController.text.trim()}';
                                
                                // Request the verification code.
                                final ok = await ref
                                    .read(forgotPasswordControllerProvider.notifier)
                                    .requestOtp(e164Phone: e164);
                                
                                if (!mounted) return;
                                
                                if (ok) {
                                  // Navigate to OTP verification & password reset screen.
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ResetPasswordScreen(phone_number: e164),
                                    ),
                                  );
                                }
                              }
                            },
                            text: AppStrings.sendCode.tr(),
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

