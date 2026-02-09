import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common_widgets/primary_button.dart';
import '../../../core/common_widgets/responsive_center.dart';
import '../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../core/constants/app_images/app_images.dart';

class CompleteProfileScreen extends ConsumerWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We might need a separate controller for this form or reuse auth controller if it has fields
    // For now, using local controllers or a new simplified structure as this is a new UI.
    // Assuming UI only for now as requested by user to match structure.

    final cityController = TextEditingController();
    final districtController = TextEditingController();
    final streetController = TextEditingController();
    final zipController = TextEditingController();
    final shortAddressController = TextEditingController();
    final emailController = TextEditingController();

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Image.asset(AppImages.logo, height: 80)),
                const SizedBox(height: 32),

                // Form Fields
                _buildLabel(context, "اسم المدينة"),
                WhiteRoundedTextFormField(
                  controller: cityController,
                  keyboardType: TextInputType.text,
                  validator: (v) => null,
                  hintText: "",
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),

                _buildLabel(context, "اسم الحي"),
                WhiteRoundedTextFormField(
                  controller: districtController,
                  keyboardType: TextInputType.text,
                  validator: (v) => null,
                  hintText: "",
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),

                _buildLabel(context, "اسم الشارع"),
                WhiteRoundedTextFormField(
                  controller: streetController,
                  keyboardType: TextInputType.text,
                  validator: (v) => null,
                  hintText: "",
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),

                _buildLabel(context, "رمز البريد"),
                WhiteRoundedTextFormField(
                  controller: zipController,
                  keyboardType: TextInputType.number,
                  validator: (v) => null,
                  hintText: "",
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),

                _buildLabel(context, "العنوان المختصر"),
                WhiteRoundedTextFormField(
                  controller: shortAddressController,
                  keyboardType: TextInputType.text,
                  validator: (v) => null,
                  hintText: "",
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),

                _buildLabel(context, "الايميل"),
                WhiteRoundedTextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => null,
                  hintText: "",
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: PrimaryButton(
                    text:
                        "تسجيل الدخول", // Sign In / Submit set to "تسجيل الدخول" as per Image 4 button (Wait, checking image 4 again)
                    // Image 4: Button is GREEN. Text is "تسجيل الدخول" (Sign In).
                    // This implies this might be the "Complete Registration" step or "Login" step.
                    // I will use "تسجيل الدخول".
                    isLoading: false,
                    onPressed: () {
                      // Logic to submit profile
                      // Navigator.of(context).push...
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Colors.black87),
      ),
    );
  }
}
