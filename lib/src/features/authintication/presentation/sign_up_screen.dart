import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common_widgets/primary_button.dart';
import '../../../core/common_widgets/responsive_center.dart';
import '../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../core/constants/app_images/app_images.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../../utils/validators.dart';
import 'auth_controller.dart';
import 'complete_profile_screen.dart';
import 'otp_screen.dart';
import 'sign_in_screen.dart';
import 'widgets/social_login_buttons.dart';
import 'country_code_provider.dart';
import '../../main_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var controller = ref.read(authControllerProvider.notifier);
    final state = ref.watch(authControllerProvider);
    final countryCode = ref.watch(countryCodeProvider);

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
                      // Logo
                      Center(child: Image.asset(AppImages.logo, height: 100)),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        AppStrings.createNewAccount.tr(),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        AppStrings.letsWinAuctions.tr(),
                        textAlign: TextAlign.end,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name Field
                            Text(
                              AppStrings.name.tr(),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            WhiteRoundedTextFormField(
                              controller: controller.nameController,
                              keyboardType: TextInputType.name,
                              validator: Validators.required,
                              hintText: AppStrings.name,
                              prefixIcon: const Icon(Icons.person),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Phone Field
                            Text(
                              AppStrings.mobileNumber.tr(),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: WhiteRoundedTextFormField(
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                validator: Validators.required,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                hintText: '5XXXXXXXX',
                                prefixIcon: CountryCodePicker(
                                  key: ValueKey(countryCode),
                                  onChanged: (country) {
                                    if (country.dialCode != null) {
                                      ref
                                          .read(countryCodeProvider.notifier)
                                          .setCountryCode(country.dialCode!);
                                    }
                                  },
                                  initialSelection: countryCode,
                                  favorite: const ['+966', 'SA'],
                                  showCountryOnly: false,
                                  showOnlyCountryWhenClosed: false,
                                  alignLeft: false,
                                  padding: EdgeInsets.zero,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            Text(
                              AppStrings.password.tr(),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
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

                            const SizedBox(height: 32),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: PrimaryButton(
                                isLoading: state.isLoading,
                                text: AppStrings.createAccount.tr(),
                                onPressed: () async {
                                  final fullphone_number =
                                      '$countryCode${controller.phoneController.text}';
                                  final result = await controller.signUp(fullphone_number);
                                  if (result['status'] == 'success' && context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => OtpScreen(
                                          phone_number: fullphone_number,
                                        ),
                                      ),
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
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social Login
                      const SocialLoginButtons(),

                      const Spacer(),

                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => SignInScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: Text(
                              AppStrings.signIn.tr(context: context),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            AppStrings.alreadyHaveAnAccount.tr(
                              context: context,
                            ),
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
