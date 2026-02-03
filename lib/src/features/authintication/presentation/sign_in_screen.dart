import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common_widgets/primary_button.dart';
import '../../../core/common_widgets/responsive_center.dart';
import '../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../core/constants/app_images/app_images.dart';

import '../../../core/constants/app_strings/app_strings.dart';
import '../../../utils/validators.dart';
import 'auth_controller.dart';
import 'otp_screen.dart';
import 'sign_up_screen.dart';
import 'widgets/social_login_buttons.dart';

class SignInScreen extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();

  SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    // Using a listener to handle navigation and errors
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next.value != null) {
        final phone = ref
            .read(authControllerProvider.notifier)
            .phoneController
            .text
            .trim();
        final e164 = '+966$phone';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OtpScreen(phoneNumber: e164),
          ),
        );
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
                      horizontal: 24.0, vertical: 16.0),
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        "اهلا بعودتك , نحن في انتظار مزاداتك القادمة", // "Welcome back..."
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Phone Number Label
                            Text(
                              "رقم الجوال", // Phone Number
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: WhiteRoundedTextFormField(
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                validator: Validators.ksaLocalPhoneValidator,
                                inputFormatters:
                                    Validators.ksaLocalPhoneInputFormatters,
                                hintText: '5XXXXXXXX',
                                prefix: '+966',
                                // Adjusted style to look cleaner (white bg, subtle border)
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
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
                            // I will KEEP it but maybe mention it's required.
                            // Wait, looking at the design again, there's "Sign In" button.
                            // If I strictly follow design, I should remove password.
                            // If I remove password, I can't call `signIn(phone, password)`.
                            // I will assume for this task I must keep it to make it work, so I'll add it.
                            WhiteRoundedTextFormField(
                              controller: controller.passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              validator: Validators.passwordValidator,
                              hintText: AppStrings.password,
                              prefixIcon: const Icon(Icons.lock),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
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
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final local =
                                        controller.phoneController.text.trim();
                                    final e164 = '+966$local';
                                    ref
                                        .read(authControllerProvider.notifier)
                                        .signIn(
                                          e164,
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
                            child: Text(AppStrings.or.tr(),
                                style: TextStyle(
                                    color: Colors.grey.shade600)), // "Or"
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
