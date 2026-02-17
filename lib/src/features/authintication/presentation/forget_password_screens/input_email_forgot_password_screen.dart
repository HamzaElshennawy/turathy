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
    // TODO: implement dispose
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
                          Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: WhiteRoundedTextFormField(
                              hintText: '5XXXXXXXX',
                              prefixIcon: const Icon(Icons.phone),
                              controller: _phoneLocalController,
                              validator: Validators.ksaLocalPhoneValidator,
                              inputFormatters:
                                  Validators.ksaLocalPhoneInputFormatters,
                              keyboardType: TextInputType.phone,
                              prefix: '+966',
                            ),
                          ),
                          const SizedBox(height: 10),
                          PrimaryButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final e164 =
                                    '+966${_phoneLocalController.text.trim()}';
                                final ok = await ref
                                    .read(
                                      forgotPasswordControllerProvider.notifier,
                                    )
                                    .requestOtp(e164Phone: e164);
                                if (!mounted) return;
                                if (ok) {
                                  // ignore: use_build_context_synchronously
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ResetPasswordScreen(
                                        phone_number: e164,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            text: AppStrings.sendCode.tr(),
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
