import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
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

  late final TextEditingController _otpTextController;
  late final FocusNode _otpFocusNode;
  late String _challengeToken;
  late String? _deliveryMethod;
  late String? _fallbackMethod;
  String? _errorMessage;
  String? _lastAutoSubmittedOtp;

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
    _otpTextController = TextEditingController();
    _otpFocusNode = FocusNode();
    _otpFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _challengeToken = widget.challengeToken;
    _deliveryMethod = widget.deliveryMethod;
    _fallbackMethod = widget.fallbackMethod;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _otpTextController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    final trimmed = digitsOnly.length > _otpLength
        ? digitsOnly.substring(0, _otpLength)
        : digitsOnly;

    if (trimmed != value || trimmed != _otpTextController.text) {
      _otpTextController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }

    _syncOtpController(trimmed);
    if (_errorMessage != null && trimmed.length < _otpLength) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }

    if (trimmed.length == _otpLength && _lastAutoSubmittedOtp != trimmed) {
      _lastAutoSubmittedOtp = trimmed;
      _submitOtp(autoTriggered: true);
    }
  }

  void _syncOtpController([String? otp]) {
    ref.read(otpControllerProvider.notifier).otpController.text =
        otp ?? _otpTextController.text;
  }

  Future<void> _submitOtp({required bool autoTriggered}) async {
    final state = ref.read(otpControllerProvider);
    final controller = ref.read(otpControllerProvider.notifier);
    final otp = _otpTextController.text;

    if (state.isLoading) {
      return;
    }

    setState(() => _errorMessage = null);
    controller.otpController.text = otp;

    if (otp.length != _otpLength) {
      if (!autoTriggered) {
        AppFunctions.showSnackBar(
          context: context,
          message: AppStrings.enter4DigitCode.tr(),
          isError: true,
        );
      }
      return;
    }

    final ok = await controller.verifyOtp(challengeToken: _challengeToken);
    if (!mounted || !ok) {
      return;
    }

    TextInput.finishAutofillContext();

    final user = ref.read(authControllerProvider).valueOrNull;
    if (user != null &&
        user.missingFields != null &&
        user.missingFields!.isNotEmpty) {
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

                // Single native OTP field with 4 visual boxes for better iOS autofill.
                AutofillGroup(
                  child: Form(
                    key: controller.formKey,
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.01,
                              child: TextFormField(
                                controller: _otpTextController,
                                focusNode: _otpFocusNode,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                autofocus: true,
                                autofillHints: const [AutofillHints.oneTimeCode],
                                enableInteractiveSelection: false,
                                showCursor: false,
                                textDirection: ui.TextDirection.ltr,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(_otpLength),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: _onOtpChanged,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _otpFocusNode.requestFocus(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(_otpLength, (index) {
                                final otp = _otpTextController.text;
                                final digit = index < otp.length ? otp[index] : '';
                                final isActive = _otpFocusNode.hasFocus &&
                                    ((otp.length == index) ||
                                        (otp.length == _otpLength &&
                                            index == _otpLength - 1));

                                return Container(
                                  width: 45,
                                  height: 55,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isActive
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    digit,
                                    textAlign: TextAlign.center,
                                    textDirection: ui.TextDirection.ltr,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      await _submitOtp(autoTriggered: false);
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
