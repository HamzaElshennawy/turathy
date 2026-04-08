/// {@category Presentation}
///
/// Authentication screen for returning users.
///
/// This screen provides a form for phone/password login, integrated
/// social login options (Google), and navigation to registration.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common_widgets/primary_button.dart';
import '../../../core/common_widgets/responsive_center.dart';
import '../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../core/constants/app_images/app_images.dart';
import '../../../core/common_widgets/phone_number_field.dart';

import '../../../core/constants/app_strings/app_strings.dart';
import '../../../utils/validators.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'complete_profile_screen.dart';
import 'otp_screen.dart';
import 'sign_up_screen.dart';
import 'forget_password_screens/input_phone_forgot_password_screen.dart';
import 'widgets/social_login_buttons.dart';
import 'country_code_provider.dart';
import '../../main_screen.dart';

/// The entry point for the sign-in experience.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final countryCode = ref.watch(countryCodeProvider);

    /// Listen to auth state changes to perform navigation or show errors.
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        setState(() {
          final err = next.error;
          _errorMessage = err is AuthException ? err.message : err.toString();
        });
      } else if (next.value != null) {
        final isGoogle = ref
            .read(authControllerProvider.notifier)
            .isGoogleSignInProcessing;

        if (isGoogle) {
          // Google Sign-In: Check if the user needs to complete their profile.
          if (next.value!.missingFields != null &&
              next.value!.missingFields!.isNotEmpty) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          }
        } else {
          // Standard Sign-In: Navigate to OTP verification for security.
          final phone = ref
              .read(authControllerProvider.notifier)
              .phoneController
              .text
              .trim();
          final e164 = '$countryCode$phone';

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => OtpScreen(phone_number: e164)),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ResponsiveCenter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // App Identity
                      Center(child: Image.asset(AppImages.logo, height: 100)),
                      const SizedBox(height: 40),

                      // Welcome Texts (RTL prioritized)
                      Text(
                        AppStrings.signIn.tr(),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.welcomeBackMessage.tr(),
                        textAlign: TextAlign.end,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Error feedback
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Login Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.mobileNumber.tr(),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            PhoneNumberField(
                              controller: controller.phoneController,
                              initialCountryCode: countryCode,
                              onCountryChanged: (country) {
                                if (country.dialCode != null) {
                                  ref
                                      .read(countryCodeProvider.notifier)
                                      .setCountryCode(country.dialCode!);
                                }
                              },
                              validator: Validators.required,
                              hintText: '5XXXXXXXXXX',
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Note: Password field is kept for backend compatibility despite OTP focus.
                            WhiteRoundedTextFormField(
                              controller: controller.passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              validator: Validators.passwordValidator,
                              hintText: AppStrings.password,
                              prefixIcon: const Icon(Icons.lock),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const InputPhoneForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppStrings.forgotPassword.tr(),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Primary Action
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: PrimaryButton(
                                isLoading: state.isLoading,
                                text: AppStrings.signIn.tr(),
                                onPressed: () async {
                                  setState(() => _errorMessage = null);
                                  if (_formKey.currentState!.validate()) {
                                    final local = controller
                                        .phoneController
                                        .text
                                        .trim();
                                    await ref
                                        .read(authControllerProvider.notifier)
                                        .signIn(
                                          '$countryCode$local',
                                          controller.passwordController.text,
                                        );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Visual switch to social login
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              AppStrings.or.tr(),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Alternative Login Methods
                      const SocialLoginButtons(),

                      const Spacer(),

                      // Footer Navigation to Registration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              AppStrings.createAccount.tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            AppStrings.dontHaveAccount.tr(),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
