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
import 'sign_in_screen.dart';
import 'widgets/social_login_buttons.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var controller = ref.read(authControllerProvider.notifier);
    final state = ref.watch(authControllerProvider);

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
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        "انشاء حساب جديد", // "Create New Account"
                        textAlign: TextAlign.end,
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
                        "هيا بنا لنفوز بالمزادات", // "Let's win auctions" - approx translation or from design
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name Field (Required by backend)
                            Text(
                              AppStrings.name.tr(), // Name
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
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            const SizedBox(height: 16),

                            // Phone Field
                            Text(
                              "رقم الجوال", // Phone
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
                                prefixIcon: const Icon(Icons.phone),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field (Required by backend)
                            Text(
                              AppStrings.password.tr(), // Password
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
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),

                            const SizedBox(height: 32),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: PrimaryButton(
                                isLoading: state.isLoading,
                                text: "انشاء الحساب", // "Create Account"
                                onPressed: () async {
                                  await controller.signUp().then((value) async {
                                    if (value) {
                                      if (context.mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SignInScreen(),
                                          ),
                                        );
                                      }
                                    }
                                  });
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
                            child: Text("أو",
                                style: TextStyle(color: Colors.grey.shade600)),
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
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => SignInScreen(),
                                ),
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
                            AppStrings.alreadyHaveAnAccount
                                .tr(context: context),
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
