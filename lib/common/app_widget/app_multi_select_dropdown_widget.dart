import 'package:flutter/material.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_const.dart';

class AppMultiSelectDropdownWidget extends StatefulWidget {
  final String labelText;
  final String hintText;
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final bool isRequired;
  final String? Function(List<String>?)? validator;

  const AppMultiSelectDropdownWidget({
    super.key,
    required this.labelText,
    this.hintText = "Select visible modules",
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.isRequired = false,
    this.validator,
  });

  @override
  State<AppMultiSelectDropdownWidget> createState() =>
      _AppMultiSelectDropdownWidgetState();
}

class _AppMultiSelectDropdownWidgetState
    extends State<AppMultiSelectDropdownWidget> {
  void _showMultiSelectDialog(FormFieldState<List<String>> field) async {
    final List<String> tempSelected = List.from(widget.selectedValues);

    final List<String>? results = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isAllSelected = tempSelected.length == widget.options.length;

            return AlertDialog(
              backgroundColor: AppColors.neutralSurface,
              surfaceTintColor: AppColors.neutralSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConst.radiusLg),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.widgets_outlined,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.labelText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                if (isAllSelected) {
                                  tempSelected.clear();
                                } else {
                                  tempSelected.clear();
                                  tempSelected.addAll(widget.options);
                                }
                              });
                            },
                            child: Text(
                              isAllSelected ? "Clear All" : "Select All",
                              style: const TextStyle(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "${tempSelected.length} selected",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.neutralTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...widget.options.map((option) {
                        final isChecked = tempSelected.contains(option);
                        return CheckboxListTile(
                          activeColor: AppColors.brandPrimary,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConst.radiusSm,
                            ),
                          ),
                          title: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isChecked
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isChecked
                                  ? AppColors.neutralTextPrimary
                                  : AppColors.neutralTextSecondary,
                            ),
                          ),
                          value: isChecked,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                if (!tempSelected.contains(option)) {
                                  tempSelected.add(option);
                                }
                              } else {
                                tempSelected.remove(option);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(
                      color: AppColors.buttonYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonDarkGreen,
                    foregroundColor: AppColors.buttonYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConst.radiusMd),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, tempSelected),
                  child: const Text(
                    "APPLY",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (results != null) {
      widget.onChanged(results);
      field.didChange(results);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: widget.selectedValues,
      validator:
          widget.validator ??
          (values) {
            final effectiveList = (values != null && values.isNotEmpty)
                ? values
                : widget.selectedValues;
            if (widget.isRequired && effectiveList.isEmpty) {
              return "Please select at least one visible module";
            }
            return null;
          },
      builder: (FormFieldState<List<String>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.labelText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.neutralTextPrimary,
                  ),
                ),
                if (widget.isRequired)
                  const Text(
                    " *",
                    style: TextStyle(
                      color: AppColors.semanticError,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _showMultiSelectDialog(field),
              borderRadius: BorderRadius.circular(AppConst.radiusMd),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurfaceSunken,
                  borderRadius: BorderRadius.circular(AppConst.radiusMd),
                  border: Border.all(
                    color: field.hasError
                        ? AppColors.semanticError
                        : AppColors.neutralBorder,
                    width: field.hasError ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.widgets_outlined,
                      color: AppColors.brandPrimary,
                      size: AppConst.iconMd,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: widget.selectedValues.isEmpty
                          ? Text(
                              widget.hintText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.neutralTextDisabled,
                              ),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: widget.selectedValues.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimarySurface,
                                    borderRadius: BorderRadius.circular(
                                      AppConst.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: AppColors.brandPrimary.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          final updated = List<String>.from(
                                            widget.selectedValues,
                                          )..remove(item);
                                          widget.onChanged(updated);
                                          field.didChange(updated);
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.neutralTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: AppColors.semanticError,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
