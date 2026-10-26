import 'dart:ui';

import 'package:flutter/material.dart';

class CinematicTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const CinematicTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<CinematicTextField> createState() => _CinematicTextFieldState();
}

class _CinematicTextFieldState extends State<CinematicTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: widget.controller,
              validator: widget.validator,
              obscureText: widget.isPassword ? _obscureText : false,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: primaryColor,
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: TextStyle(
                  color: _isFocused ? primaryColor : Colors.white60,
                  fontSize: 14,
                ),
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  color: _isFocused ? primaryColor : Colors.white54,
                  size: 20,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B).withValues(alpha: 0.65),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 1.8),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFEF4444),
                    width: 1.2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFEF4444),
                    width: 1.8,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
