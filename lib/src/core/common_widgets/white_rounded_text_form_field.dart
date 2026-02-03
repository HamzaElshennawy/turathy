import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter/services.dart';

class WhiteRoundedTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final BorderSide? borderSide;
  final List<TextInputFormatter>? inputFormatters;

  final TextInputType keyboardType;
  final String hintText;
  final bool readOnly;
  final String? prefix;
  final Widget? prefixIcon;
  final TextAlign textAlign;

  final void Function()? onTab;

  final void Function(String)? onChanged;

  final void Function(String)? onFieldSubmitted;

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
  final FocusNode _focusNode = FocusNode();
  bool isFocused = false;

  @override
  void initState() {
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
    super.initState();
  }

  late bool isObscureText =
      widget.keyboardType == TextInputType.visiblePassword;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      child: TextFormField(
        textDirection: ui.TextDirection.ltr,
        focusNode: _focusNode,
        textAlign: widget.textAlign,
        onChanged: widget.onChanged,
        onTap: widget.onTab,
        onFieldSubmitted: widget.onFieldSubmitted,
        onTapOutside: (details) {
          _focusNode.unfocus();
        },
        inputFormatters: widget.inputFormatters,
        readOnly: widget.readOnly,
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        obscureText: isObscureText,
        decoration: InputDecoration(
          // prefix: prefix,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 60,
            // maxHeight: 100,
          ),
          prefixIcon: widget.prefixIcon,
          prefixIconColor:
              isFocused ? Theme.of(context).colorScheme.primary : Colors.grey,
          prefixText: widget.prefix,
          // prefixStyle: AppTextStyle.materialThemeBodyLarge,
          filled: true,
          //fillColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(
          //    Theme.of(context).brightness == Brightness.dark ? .2 : .6),
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
          // hintStyle: AppTextStyle.materialThemeBodyLarge,
        ),
      ),
    );
  }
}
