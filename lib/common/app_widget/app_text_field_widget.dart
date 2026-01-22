import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Debug:Update AppTextFieldWidget
typedef FieldValidator<T> = String? Function(T? value);

class AppTextFieldWidget extends StatefulWidget {
  final String? labelText;
  final EdgeInsetsGeometry? labelTextPadding;
  final String? hintText;
  final String? errorText;
  final bool isPasswordTextField;
  final TextEditingController textFieldController;
  final Widget? suffixIconWidget;
  final Widget? prefixIconWidget;
  final TextStyle? textStyle;
  final EdgeInsets margin;
  final FormFieldValidator<String>? validator;
  final bool isEnabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final FloatingLabelBehavior floatingLabelBehavior;
  final TextStyle? labelTextStyle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autoFocus;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final EdgeInsets? contentPadding;
  final bool isExpand;
  final String autoFillHint;
  final bool? disableFocusBorder;
  final double? borderRadius;
  final bool? showAsterisk;
  final bool isRequired;
  final TextStyle? hintTextStyle;

  final InputDecoration? decoration;

  const AppTextFieldWidget({
    super.key,
    this.borderRadius,
    this.labelText,
    this.labelTextPadding,
    this.hintText,
    this.isPasswordTextField = false,
    required this.textFieldController,
    this.errorText,
    this.prefixIconWidget,
    this.suffixIconWidget,
    this.textStyle,
    this.margin = const EdgeInsets.all(0.0),
    this.validator,
    this.isEnabled = true,
    this.readOnly = false,
    this.inputFormatters,
    this.autoFocus = false,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
    this.labelTextStyle,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.focusNode,
    this.isExpand = false,
    this.disableFocusBorder = false,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.autoFillHint = '',
    this.showAsterisk,
    this.isRequired = false,
    this.decoration,
    this.hintTextStyle,
  });

  @override
  AppTextFieldWidgetState createState() => AppTextFieldWidgetState();
}

class AppTextFieldWidgetState extends State<AppTextFieldWidget> {
  bool isShowPassword = true;
  bool isErrorShow = false;
  double borderRadius = 0;
  @override
  void initState() {
    borderRadius = widget.borderRadius ?? appHorizontalPadding10;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      child: widget.isExpand
          ? IntrinsicHeight(child: mainTextFieldWidget())
          : mainTextFieldWidget(),
    );
  }

  Widget mainTextFieldWidget() {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppColors.greyTextColor,
        hintColor: isErrorShow
            ? AppColors.redTextStatusColor
            : AppColors.greyTextColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.labelText != null)
            Row(
              children: [
                Flexible(
                  child: Padding(
                    padding:
                    widget.labelTextPadding ??
                        const EdgeInsets.only(bottom: 7.0),
                    child: Text(
                      widget.labelText!,
                      style:
                      widget.labelTextStyle ??
                          AppThemeData.textFieldTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey90TextColor,
                          ),
                    ),
                  ),
                ),
                if (widget.isRequired || (widget.showAsterisk ?? false))
                  const Text(
                    '*',
                    style: TextStyle(fontSize: 16.0, color: Colors.red),
                  ),
              ],
            ),
          TextFormField(
            autofocus: widget.autoFocus,
            style:
            widget.textStyle ??
                AppThemeData.textFieldTextStyle.copyWith(
                  color: AppColors.blackTextColor,
                ),
            enabled: widget.isEnabled,
            maxLength: widget.maxLength,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            expands: widget.isExpand,
            minLines: widget.isExpand ? null : widget.minLines,
            maxLines: widget.isExpand ? null : widget.maxLines,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            onEditingComplete: widget.onEditingComplete,
            // onFieldSubmitted: widget.onFieldSubmitted,
            onSaved: widget.onSaved,
            textCapitalization: widget.textCapitalization,
            controller: widget.textFieldController,
            onFieldSubmitted: (value) {
              FocusScope.of(context).unfocus();
            },
            obscureText: widget.isPasswordTextField ? isShowPassword : false,
            validator: (v) {
              // Required field validation
              if (widget.isRequired && (v == null || v.trim().isEmpty)) {
                setState(() {
                  isErrorShow = true;
                });
                return 'This field is required';
              }

              // Custom validator (if provided)
              if (widget.validator != null) {
                final result = widget.validator!.call(v);
                setState(() {
                  isErrorShow = result != null;
                });
                return result;
              }

              setState(() {
                isErrorShow = false;
              });
              return null;
            },
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            focusNode: widget.focusNode,
            cursorColor: AppColors.primary,
            autofillHints: widget.autoFillHint.isNotEmpty
                ? [widget.autoFillHint]
                : null,
            decoration: InputDecoration(
              isDense: true,
              floatingLabelBehavior: widget.floatingLabelBehavior,
              errorText: widget.errorText,
              errorMaxLines: 10,
              errorStyle: AppThemeData.errorTextFieldStyle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1,
                  style: BorderStyle.none,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: AppColors.redTextStatusColor,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: AppColors.redTextStatusColor,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(width: 0, style: BorderStyle.none),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(width: 0, style: BorderStyle.none),
              ),
              focusedBorder: widget.disableFocusBorder == true
                  ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                  width: 0,
                  style: BorderStyle.none,
                ),
              )
                  : OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.greyTextFormFiledColor!,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              fillColor: AppColors.greyTextFormFiledColor,
              filled: true,
              prefixIcon: widget.prefixIconWidget,
              suffixIcon:
              widget.suffixIconWidget ??
                  (widget.isPasswordTextField
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.focusNode != null) {
                              widget.focusNode!.unfocus();
                              widget.focusNode!.canRequestFocus = false;
                            }
                            setState(() {
                              isShowPassword = !isShowPassword;
                            });
                            if (widget.focusNode != null) {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                    () {
                                  widget.focusNode!.canRequestFocus =
                                  true;
                                },
                              );
                            }
                          },
                          child: Icon(
                            isShowPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.kPrimaryColor,
                            size: 23,
                          ),
                        ),
                      ),
                    ],
                  )
                      : null),
              hintText: widget.hintText,
              hintStyle:
              widget.hintTextStyle ??
                  AppThemeData.textFieldTextStyle.copyWith(
                    color: AppColors.greyLoginTextColor,
                  ),
              contentPadding:
              widget.contentPadding ??
                  const EdgeInsets.fromLTRB(
                    appHorizontalPadding10,
                    appHorizontalPadding20,
                    appHorizontalPadding10,
                    appHorizontalPadding20,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
