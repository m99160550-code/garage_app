import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Search field (UI/UX spec 1.7): 48 pt pill, `surface.card` fill, search
/// icon at the start, clear (×) button once there is text.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.clearLabel,
    this.controller,
    this.autofocus = false,
    this.focusNode,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  /// Screen-reader label for the clear button.
  final String clearLabel;
  final TextEditingController? controller;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final pill = BorderRadius.circular(AppRadii.pill);

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      style: text.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: text.body.copyWith(color: colors.textTertiary),
        filled: true,
        fillColor: colors.surfaceCard,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Icon(Icons.search, size: 20, color: colors.textSecondary),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: widget.clearLabel,
                icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
                onPressed: _clear,
              ),
        border: OutlineInputBorder(
          borderRadius: pill,
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: pill,
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: pill,
          borderSide: BorderSide(color: colors.accentPrimary, width: 2),
        ),
      ),
    );
  }
}
