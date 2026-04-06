/// {@category Components}
///
/// A stylized, high-accessibility text input field tailored for the project's light theme.
/// 
/// [WhiteRoundedTextFormField] serves as the standard input for forms, search bars, 
/// and authentication flows. It provides several UX enhancements over a raw 
/// [TextFormField]:
/// - **Focus Visualization**: Dynamically colors the prefix icon when the field is active.
/// - **Integrated Security**: Automatically adds a visibility toggle for password types.
/// - **Layout Discipline**: Enforces a maximum width of 400dp to preserve vertical 
///   rhythm on tablets.
/// - **Localization Built-in**: Automates the call to `.tr()` for hint text strings.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter/services.dart';

/// A robust, state-aware text entry field with a customized material design.
class WhiteRoundedTextFormField extends StatefulWidget {
  /// The controller managing the current text buffer.
  final TextEditingController controller;

  /// Logic to validate the input string (e.g., regex checks).
  final String? Function(String?)? validator;

  /// Optional custom border configuration. Defaults to [BorderSide.none].
  final BorderSide? borderSide;

  /// A list of formatters to constrain input (e.g., number-only, character limits).
  final List<TextInputFormatter>? inputFormatters;

  /// The semantic type of input (e.g., [TextInputType.emailAddress]).
  final TextInputType keyboardType;

  /// The placeholder text (localization keys are supported).
  final String hintText;

  /// If true, the field is non-interactive but still displays its current value.
  final bool readOnly;

  /// Optional non-editable text prefix (e.g., a currency symbol or country code).
  final String? prefix;

  /// A leading icon or widget to contextualize the input.
  final Widget? prefixIcon;

  /// Horizontal alignment of the inner text. Defaults to [TextAlign.start].
  final TextAlign textAlign;

  /// Callback emitted when the user taps into the field.
  final void Function()? onTab;

  /// Callback emitted for every character change.
  final void Function(String)? onChanged;

  /// Callback emitted when the user clicks 'Done' or 'Enter' on their keyboard.
  final void Function(String)? onFieldSubmitted;

  /// Creates a [WhiteRoundedTextFormField] with a mandatory controller and hint.
  const WhiteRoundedTextFormField({
    super.key,
    required this.controller,
    required this.validator,
    this.borderSide,
    required this.keyboardType,
    required this.hintText,
    this.readOnly = false,
    this.inputFormatters,
    this.onTab,
    this.onChanged,
    this.prefix,
    this.prefixIcon,
    this.textAlign = TextAlign.start,
    this.onFieldSubmitted,
  });

  @override
  State<WhiteRoundedTextFormField> createState() =>
      _WhiteRoundedTextFormFieldState();
}

class _WhiteRoundedTextFormFieldState extends State<WhiteRoundedTextFormField> {
  /// Managed focus node to track active/inactive states for styling.
  final FocusNode _focusNode = FocusNode();
  
  /// Internal flag for dynamic highlighting.
  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  /// Toggleable state for obfuscated text, initialized based on [widget.keyboardType].
  late bool isObscureText =
      widget.keyboardType == TextInputType.visiblePassword;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400, // Design constraint for form readability
      ),
      child: TextFormField(
        // Enforce LTR for predictable digit and cursor behavior across locales.
        textDirection: ui.TextDirection.ltr,
        focusNode: _focusNode,
        textAlign: widget.textAlign,
        onChanged: widget.onChanged,
        onTap: widget.onTab,
        onFieldSubmitted: widget.onFieldSubmitted,
        onTapOutside: (details) {
          _focusNode.unfocus(); // UX: Dismiss keyboard when user taps elsewhere
        },
        inputFormatters: widget.inputFormatters,
        readOnly: widget.readOnly,
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        obscureText: isObscureText,
        decoration: InputDecoration(
          prefixIconConstraints: const BoxConstraints(
            minWidth: 60,
          ),
          prefixIcon: widget.prefixIcon,
          // Design: Highlight icon with primary color only when focused
          prefixIconColor:
              isFocused ? Theme.of(context).colorScheme.primary : Colors.grey,
          prefixText: widget.prefix,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderSide: widget.borderSide ?? BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: widget.borderSide ?? BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
          hintText: widget.hintText.tr(),
          // Strategy: Auto-inject eye-icon for passwords
          suffixIcon: widget.keyboardType == TextInputType.visiblePassword
              ? IconButton(
                  icon: Icon(
                    isObscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      isObscureText = !isObscureText;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

