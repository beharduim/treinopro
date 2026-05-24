import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Permite limpar ou focar os campos OTP a partir do widget pai.
class OtpPinInputController {
  VoidCallback? _clear;
  VoidCallback? _focusFirst;
  String Function()? _getCode;

  void attach({
    required VoidCallback clear,
    required VoidCallback focusFirst,
    required String Function() getCode,
  }) {
    _clear = clear;
    _focusFirst = focusFirst;
    _getCode = getCode;
  }

  void detach() {
    _clear = null;
    _focusFirst = null;
    _getCode = null;
  }

  void clear() => _clear?.call();

  void focusFirst() => _focusFirst?.call();

  String get code => _getCode?.call() ?? '';
}

/// Campo OTP com caixas individuais, suporte a colar código completo e autofill nativo.
class OtpPinInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final OtpPinInputController? controller;
  final bool enabled;
  final bool autofocus;
  final double boxWidth;
  final double boxHeight;
  final Color activeBorderColor;
  final Color inactiveBorderColor;
  final TextStyle? textStyle;

  const OtpPinInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.controller,
    this.enabled = true,
    this.autofocus = false,
    this.boxWidth = 45,
    this.boxHeight = 55,
    this.activeBorderColor = AppColors.primaryOrange,
    this.inactiveBorderColor = AppColors.secondaryDark,
    this.textStyle,
  }) : assert(length > 0 && length <= 8);

  @override
  State<OtpPinInput> createState() => _OtpPinInputState();
}

class _OtpPinInputState extends State<OtpPinInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final TextEditingController _autofillController;
  late final FocusNode _autofillFocusNode;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _autofillController = TextEditingController();
    _autofillFocusNode = FocusNode();

    _autofillController.addListener(_onAutofillChanged);

    widget.controller?.attach(
      clear: _clearAll,
      focusFirst: _focusFirstCell,
      getCode: _currentCode,
    );

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusFirstCell();
      });
    }
  }

  @override
  void didUpdateWidget(covariant OtpPinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(
        clear: _clearAll,
        focusFirst: _focusFirstCell,
        getCode: _currentCode,
      );
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _autofillController.removeListener(_onAutofillChanged);
    _autofillController.dispose();
    _autofillFocusNode.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _currentCode() => _controllers.map((c) => c.text).join();

  void _notifyChanged() {
    final code = _currentCode();
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
    setState(() {});
  }

  void _onAutofillChanged() {
    final text = _autofillController.text;
    if (text.isEmpty) return;

    final digits = _extractDigits(text);
    if (digits.isEmpty) return;

    _applyCode(digits);
    _autofillController.clear();
  }

  String _extractDigits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  void _applyCode(String raw, {int startIndex = 0}) {
    final digits = _extractDigits(raw);
    if (digits.isEmpty) return;

    for (var i = startIndex; i < widget.length; i++) {
      _controllers[i].text = '';
    }

    var writeIndex = startIndex;
    for (final digit in digits.split('')) {
      if (writeIndex >= widget.length) break;
      _controllers[writeIndex].text = digit;
      writeIndex++;
    }

    if (writeIndex >= widget.length) {
      _focusNodes[widget.length - 1].unfocus();
    } else {
      _focusNodes[writeIndex].requestFocus();
    }

    _notifyChanged();
  }

  void _onDigitChanged(String value, int index) {
    if (value.length > 1) {
      _applyCode(value, startIndex: index);
      return;
    }

    if (value.length == 1) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    _notifyChanged();
  }

  void _clearAll() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _autofillController.clear();
    _focusFirstCell();
    _notifyChanged();
  }

  void _focusFirstCell() {
    if (!widget.enabled) return;
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        widget.textStyle ??
        AppTextStyles.h6Semibold.copyWith(color: AppColors.secondary);

    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Campo oculto para autofill nativo (SMS/e-mail) no iOS e Android.
          SizedBox(
            width: 0,
            height: 0,
            child: TextField(
              controller: _autofillController,
              focusNode: _autofillFocusNode,
              autofillHints: const [AutofillHints.oneTimeCode],
              keyboardType: TextInputType.number,
              enableSuggestions: false,
              autocorrect: false,
              enabled: widget.enabled,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.length, (index) {
              final hasValue = _controllers[index].text.isNotEmpty;
              final inactiveColor = widget.inactiveBorderColor.withValues(
                alpha: 0.3,
              );

              return SizedBox(
                width: widget.boxWidth,
                height: widget.boxHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: hasValue
                          ? widget.activeBorderColor
                          : inactiveColor,
                      width: hasValue ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: widget.enabled,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    enableSuggestions: false,
                    autocorrect: false,
                    enableInteractiveSelection: true,
                    autofillHints: index == 0
                        ? const [AutofillHints.oneTimeCode]
                        : null,
                    style: textStyle,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _OtpCellInputFormatter(
                        onPaste: (pasted) =>
                            _applyCode(pasted, startIndex: index),
                      ),
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => _onDigitChanged(value, index),
                    onTap: () {
                      _controllers[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _controllers[index].text.length,
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OtpCellInputFormatter extends TextInputFormatter {
  final void Function(String pasted) onPaste;

  _OtpCellInputFormatter({required this.onPaste});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length > 1) {
      onPaste(newValue.text);
      return TextEditingValue(
        text: oldValue.text,
        selection: TextSelection.collapsed(offset: oldValue.text.length),
      );
    }

    return newValue;
  }
}
