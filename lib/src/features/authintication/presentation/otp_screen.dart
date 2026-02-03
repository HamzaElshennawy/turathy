import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common_widgets/primary_button.dart';
import '../../../core/common_widgets/responsive_center.dart';
import '../../../core/constants/app_images/app_images.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import 'otp_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  // We need 6 controllers for the 6 digits if we manage them manually
  // Or one main controller and focus/text logic.
  // Using 6 controllers for simplicity in UI state management for focus.
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error.toString())));
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    AppImages.logo,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "تحقق من عنوان جوالك", // "Verify your mobile address" / Check phone
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "أدخل الرمز المكون من 6 أرقام الذي ارسلناه إلى رقمك ${widget.phoneNumber}",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 40),

                // 6 Digit Input
                Form(
                  key: controller.formKey,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 45,
                        height: 55,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                          onChanged: (value) => _onDigitChanged(index, value),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 24),

                // Timer / Hint
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "مؤقت 00:45 ثانية",
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
                      // Update the main controller text before verifying just in case
                      String otp = _controllers.map((c) => c.text).join();
                      controller.otpController.text = otp;

                      if (otp.length == 6) {
                        // Manually validate to avoid form key issues with multiple fields if needed
                        // Or just call verify
                        final ok = await controller.verifyOtp(
                            phoneNumber: widget.phoneNumber);
                        if (ok && context.mounted) {
                          // Navigate safely
                          Navigator.of(context).pop();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter 6 digits")),
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
                          await controller.resendOtp(
                              phoneNumber: widget.phoneNumber);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    AppStrings.otpResentSuccessfully.tr())));
                          }
                        },
                  child: Text(
                    "إعادة إرسال الرمز", // Resend Code
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold),
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
