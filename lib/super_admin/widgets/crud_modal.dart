import 'package:flutter/material.dart';

import '../core/responsive/adaptive_gap.dart';
import '../core/responsive/adaptive_text.dart';
import '../core/responsive/responsive_extensions.dart';
import '../core/responsive/responsive_values.dart';

class CrudModal extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> fields;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const CrudModal({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final isSmall = context.narrowerThan(520);
    final cornerRadius = ResponsiveValues.cardRadius(context) * 2.2;
    final sectionGap = ResponsiveValues.gap(context) * 2;
    final fieldGap = ResponsiveValues.gap(context) * 0.6;
    final fieldSurface = Color.alphaBlend(
      scheme.primary.withValues(alpha: isLight ? 0.08 : 0.16),
      theme.cardColor,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 24,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: context.screenHeight * 0.88,
        ),
        child: Container(
          padding: EdgeInsets.all(isSmall ? 18 : 32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color:
                    theme.shadowColor.withValues(alpha: isLight ? 0.1 : 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.responsive(
                          compact: 21,
                          medium: 22,
                          expanded: 24,
                          large: 24,
                        ),
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancel,
                      child: Icon(
                        Icons.close,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
                AdaptiveGap(compact: sectionGap),
                ...fields.map((field) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: sectionGap - 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdaptiveText(
                          field['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        AdaptiveGap(compact: fieldGap),
                        if (field['type'] == 'select')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: fieldSurface,
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(cornerRadius),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: field['value'] as String?,
                                isExpanded: true,
                                onChanged: (value) {
                                  final onChanged = field['onChanged']
                                      as ValueChanged<String?>?;
                                  onChanged?.call(value);
                                },
                                items: (field['options']
                                        as List<Map<String, String>>)
                                    .map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option['value'],
                                    child: Text(option['label']!),
                                  );
                                }).toList(),
                                style: TextStyle(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          )
                        else
                          TextFormField(
                            initialValue: field['value']?.toString(),
                            onChanged:
                                field['onChanged'] as ValueChanged<String>?,
                            keyboardType:
                                field['keyboardType'] as TextInputType?,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(cornerRadius),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(cornerRadius),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(cornerRadius),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: fieldSurface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                AdaptiveGap(compact: ResponsiveValues.gap(context)),
                if (isSmall)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: onSave,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(cornerRadius),
                          ),
                          child: Center(
                            child: AdaptiveText(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AdaptiveGap(compact: ResponsiveValues.gap(context)),
                      GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: fieldSurface,
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(cornerRadius),
                          ),
                          child: Center(
                            child: AdaptiveText(
                              'Cancel',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onSave,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(cornerRadius),
                            ),
                            child: Center(
                              child: AdaptiveText(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AdaptiveGap(
                        axis: Axis.horizontal,
                        compact: ResponsiveValues.gap(context),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: fieldSurface,
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(cornerRadius),
                            ),
                            child: Center(
                              child: AdaptiveText(
                                'Cancel',
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
