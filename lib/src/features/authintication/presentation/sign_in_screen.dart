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
import 'widgets/social_login_buttons.dart';
import 'country_code_provider.dart';
import '../../main_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final countryCode = ref.watch(countryCodeProvider);

    // Using a listener to handle navigation and errors
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        setState(() {
          final err = next.error;
          if (err is AuthException) {
            _errorMessage = err.message;
          } else {
            _errorMessage = err.toString();
          }
        });
      } else if (next.value != null) {
        final isGoogle = ref
            .read(authControllerProvider.notifier)
            .isGoogleSignInProcessing;
        if (isGoogle) {
          if (next.value!.missingFields != null && next.value!.missingFields!.isNotEmpty) {
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
          // Normal sign-in: always check OTP as requested by user
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
      backgroundColor:
          Colors.white, // Setting white background as per cleaner design
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
                      // Logo
                      Center(
                        child: Image.asset(
                          AppImages.logo,
                          height: 100,
                          // width: MediaQuery.of(context).size.width / 2, // Adjusted for cleaner look
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        AppStrings.signIn.tr(),
                        textAlign: TextAlign
                            .end, // RTL alignment by default for Arabic
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        AppStrings.welcomeBackMessage.tr(),
                        textAlign: TextAlign.end,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Inline error message
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

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Phone Number Label
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

                            // Password (Hidden in new design but required by backend)
                            // We keep it but style it minimally
                            // Text(
                            //   AppStrings.password.tr(),
                            //   textAlign: TextAlign.end,
                            //   style: Theme.of(context).textTheme.titleMedium,
                            // ),
                            // const SizedBox(height: 8),
                            // WhiteRoundedTextFormField(
                            //   controller: controller.passwordController,
                            //   keyboardType: TextInputType.visiblePassword,
                            //   validator: Validators.passwordValidator,
                            //   hintText: '********',
                            //   prefixIcon: const Icon(Icons.lock_outline),
                            //   borderSide: BorderSide(color: Colors.grey.shade300),
                            // ),

                            // Hiding Password Field visually IF the intent is truly OTP only,
                            // BUT current backend endpoint requires password.
                            // I will keep it VISIBLE for now as per plan, but minimal.
                            // Actually, the user asked to "follow the structure of this app" + "change sign in to be like these designs".
                            // The design DOES NOT have a password field. It looks like an OTP flow.
                            // If I hide it, login will fail.
                            // I will assume for this task I must keep it to make it work, so I'll add it.
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

                            // Forgot Password
                            // Align(
                            //   alignment: AlignmentDirectional.centerStart,
                            //   child: TextButton(
                            //     onPressed: () {
                            //       Navigator.of(context).push(
                            //         MaterialPageRoute(
                            //           builder: (context) => const InputEmailForgotPasswordScreen(),
                            //         ),
                            //       );
                            //     },
                            //     child: Text(
                            //       AppStrings.forgotPassword.tr(),
                            //       style: const TextStyle(color: Colors.grey),
                            //     ),
                            //   ),
                            // ),
                            const SizedBox(height: 32),

                            // Sign In Button
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

                      // Divider "Or"
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              AppStrings.or.tr(),
                              style: TextStyle(color: Colors.grey.shade600),
                            ), // "Or"
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social Login
                      const SocialLoginButtons(),

                      const Spacer(),

                      // Don't have account
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
                              AppStrings.createAccount.tr(), // "Create Account"
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            AppStrings.dontHaveAccount
                                .tr(), // "Don't have an account?"
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
