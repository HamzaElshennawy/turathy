/// {@category Presentation}
///
/// Starting screen for the "Forgot Password" flow.
/// 
/// This screen prompts the user to enter their registered phone number
/// (currently limited to KSA +966) to receive a password reset code.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/common_widgets/primary_button.dart';
import '../../../../core/common_widgets/responsive_center.dart';
import '../../../../core/constants/app_images/app_images.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings/app_strings.dart';
import '../../../../utils/validators.dart';
import '../../../../core/common_widgets/phone_number_field.dart';
import '../country_code_provider.dart';
import '../auth_controller.dart';
import 'reset_password_screen.dart';
import 'forgot_password_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for entering the phone number to initiate password reset.
class InputPhoneForgotPasswordScreen extends ConsumerStatefulWidget {
  const InputPhoneForgotPasswordScreen({super.key});

  @override
  ConsumerState<InputPhoneForgotPasswordScreen> createState() =>
      _InputPhoneForgotPasswordScreenState();
}

class _InputPhoneForgotPasswordScreenState
    extends ConsumerState<InputPhoneForgotPasswordScreen> {
  final TextEditingController _phoneLocalController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneLocalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countryCode = ref.watch(countryCodeProvider);

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
                          
                          PhoneNumberField(
                            controller: _phoneLocalController,
                            initialCountryCode: countryCode,
                            onCountryChanged: (country) {
                              if (country.dialCode != null) {
                                ref.read(countryCodeProvider.notifier).setCountryCode(country.dialCode!);
                              }
                            },
                            validator: Validators.required,
                            hintText: '5XXXXXXXXXX',
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          const SizedBox(height: 10),
                          
                          // Action Button
                          PrimaryButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final e164 = '$countryCode${_phoneLocalController.text.trim()}';
                                
                                // Request the verification code.
                                final ok = await ref
                                    .read(forgotPasswordControllerProvider.notifier)
                                    .requestOtp(e164Phone: e164);
                                
                                if (!mounted) return;
                                
                                if (ok) {
                                  // Pass the phone number back to the login state for continuity
                                  ref.read(authControllerProvider.notifier).phoneController.text = _phoneLocalController.text.trim();

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

