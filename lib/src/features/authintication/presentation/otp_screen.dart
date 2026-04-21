import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common_widgets/primary_button.dart';
import '../../../core/common_widgets/responsive_center.dart';
import '../../../core/constants/app_functions/app_functions.dart';
import '../../../core/constants/app_images/app_images.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import 'auth_controller.dart';
import 'complete_profile_screen.dart';
import '../data/auth_repository.dart';
import 'otp_controller.dart';
import '../../main_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone_number;
  final String challengeToken;
  final String? deliveryMethod;
  final String? fallbackMethod;

  const OtpScreen({
    super.key,
    required this.phone_number,
    required this.challengeToken,
    this.deliveryMethod,
    this.fallbackMethod,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _otpLength = 4;

  // We need one controller per digit if we manage them manually
  // Or one main controller and focus/text logic.
  // Using 4 controllers for simplicity in UI state management for focus.
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late String _challengeToken;
  late String? _deliveryMethod;
  late String? _fallbackMethod;
  String? _errorMessage;

  String _buildDeliveryMessage() {
    if (_deliveryMethod == 'whatsapp' && _fallbackMethod == 'sms') {
      return AppStrings.otpWillBeSentByWhatsappWithSmsFallback.tr();
    }
    if (_deliveryMethod == 'whatsapp') {
      return AppStrings.otpWillBeSentByWhatsapp.tr();
    }
    return AppStrings.otpWillBeSentBySms.tr();
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _challengeToken = widget.challengeToken;
    _deliveryMethod = widget.deliveryMethod;
    _fallbackMethod = widget.fallbackMethod;
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Combine text for the main controller logic if needed,
    // or just pass combined string to verify.
    String otp = _controllers.map((c) => c.text).join();
    ref.read(otpControllerProvider.notifier).otpController.text = otp;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpControllerProvider);
    final controller = ref.read(otpControllerProvider.notifier);

    // Listen for errors/success is handled somewhat in controller or parent,
    // but we should re-add the listener from original code.
    ref.listen(otpControllerProvider, (previous, next) {
      if (next.error != null) {
        final friendlyMessage = getFriendlyAuthMessage(next.error);
        setState(() {
          _errorMessage = friendlyMessage;
        });
        AppFunctions.showSnackBar(
          context: context,
          message: friendlyMessage,
          isError: true,
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
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
                Center(child: Image.asset(AppImages.logo, height: 80)),
                const SizedBox(height: 40),
                Text(
                  AppStrings.verifyOtp.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.enterOtpForNumber.tr(args: [widget.phone_number]),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  _buildDeliveryMessage(),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 40),

                // 4 Digit Input
                Form(
                  key: controller.formKey,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, (index) {
                      return SizedBox(
                        width: 45,
                        height: 55,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onDigitChanged(index, value),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // Inline error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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

                const SizedBox(height: 8),

                // Timer / Hint
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.otpCodeExpiresIn.tr(args: ['00:45']),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  height: 50,
                  child: PrimaryButton(
                    text: AppStrings.verify.tr(),
                    isLoading: state.isLoading,
                    onPressed: () async {
                      setState(() => _errorMessage = null);
                      // Update the main controller text before verifying just in case
                      String otp = _controllers.map((c) => c.text).join();
                      controller.otpController.text = otp;

                      if (otp.length == _otpLength) {
                        // Manually validate to avoid form key issues with multiple fields if needed
                        // Or just call verify
                        final ok = await controller.verifyOtp(
                          challengeToken: _challengeToken,
                        );
                        if (ok && context.mounted) {
                          final user = ref.read(authControllerProvider).valueOrNull;
                          if (user != null && user.missingFields != null && user.missingFields!.isNotEmpty) {
                             Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
                            );
                          } else {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const MainScreen()),
                              (route) => false,
                            );
                          }
                        }
                      } else {
                        AppFunctions.showSnackBar(
                          context: context,
                          message: AppStrings.enter4DigitCode.tr(),
                          isError: true,
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Resend
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final resendResult = await controller.resendOtp(
                            challengeToken: _challengeToken,
                          );
                          if (resendResult != null) {
                            setState(() {
                              _challengeToken =
                                  resendResult['challengeToken'] as String;
                              _deliveryMethod =
                                  resendResult['deliveryMethod'] as String?;
                              _fallbackMethod =
                                  resendResult['fallbackMethod'] as String?;
                            });
                          }
                          if (context.mounted && resendResult != null) {
                            AppFunctions.showSnackBar(
                              context: context,
                              message: AppStrings.otpResentSuccessfully.tr(),
                            );
                          }
                        },
                  child: Text(
                    AppStrings.resendCode.tr(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
