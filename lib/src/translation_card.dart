import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

import 'expandable_text.dart';

/// Color scheme for section styling
class _SectionColors {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _SectionColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

/// Helper class for generating section colors
class _SectionColorHelper {
  /// Generates section colors for light/dark theme
  /// [baseColor] is the base MaterialColor (e.g., Colors.blue, Colors.orange)
  /// [lightShade] is the shade number for light theme text (e.g., 700, 800)
  /// [darkShade] is the shade number for dark theme text (e.g., 200)
  static _SectionColors getSectionColors(
    MaterialColor baseColor,
    bool isDark,
    int lightShade,
    int darkShade,
  ) {
    return _SectionColors(
      backgroundColor: isDark
          ? baseColor.withValues(alpha: 0.15)
          : baseColor.withValues(alpha: 0.08),
      textColor: isDark ? baseColor[darkShade]! : baseColor[lightShade]!,
      borderColor: isDark
          ? baseColor.withValues(alpha: 0.3)
          : baseColor.withValues(alpha: 0.2),
    );
  }
}

/// Widget for displaying a single translation card
class TranslationCard extends StatelessWidget {
  final String translationKey;
  final String defaultText;
  final dynamic targetValue;
  final bool showKey;
  final bool isFlashing;
  final double flashValue;
  final LanguageCodes? defaultLanguage;
  final LanguageCodes? targetLanguage;
  final TextEditingController? textController;
  final LanguageConditions? defaultCondition;
  final VoidCallback onCardTap;
  final VoidCallback? onConvertStringToCondition;
  final VoidCallback? onConvertConditionToString;
  final VoidCallback? onEditCondition;

  const TranslationCard({
    super.key,
    required this.translationKey,
    required this.defaultText,
    required this.targetValue,
    required this.showKey,
    required this.isFlashing,
    required this.flashValue,
    this.defaultLanguage,
    this.targetLanguage,
    this.textController,
    this.defaultCondition,
    required this.onCardTap,
    this.onConvertStringToCondition,
    this.onConvertConditionToString,
    this.onEditCondition,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final dividerColor = theme.dividerColor;
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    // Flash highlight color - use blue with higher opacity for clearer visibility
    final flashBlue = isDark
        ? Colors.blue.withValues(alpha: 0.5) // More visible in dark
        : Colors.blue.shade100; // Clearer in light

    final flashBorderBlue = isDark
        ? Colors
              .blue
              .shade300 // Brighter blue in dark
        : Colors.blue.shade500; // Brighter blue in light

    // Calculate animated colors based on flash value
    final backgroundColor = isFlashing
        ? Color.lerp(cardColor, flashBlue, flashValue)!
        : cardColor;

    final borderColor = isFlashing
        ? Color.lerp(dividerColor, flashBorderBlue, flashValue)!
        : dividerColor;

    final borderWidth = isFlashing ? 2.0 + (flashValue * 2.0) : 1.0;
    final elevation = isFlashing ? 4.0 + (flashValue * 4.0) : 2.0;

    return GestureDetector(
      onTap: onCardTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        elevation: elevation,
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        shadowColor: isFlashing
            ? Colors.blue.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.08),
        child: LanguageBuilder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Translation key - only show if showKey is true
                  if (showKey) ...[
                    _buildKeySection(context),
                    const SizedBox(height: 12),
                  ],

                  // Default language translation
                  if (targetValue is String)
                    _buildDefaultStringSection(context)
                  else if (targetValue is LanguageConditions)
                    _buildDefaultConditionSection(context),

                  const SizedBox(height: 12),

                  // Target language translation (editable)
                  if (targetValue is String)
                    _buildTargetStringSection(context, theme, isDark)
                  else if (targetValue is LanguageConditions)
                    _buildTargetConditionSection(context)
                  else
                    _buildTargetOtherSection(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKeySection(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final colors = _SectionColorHelper.getSectionColors(
      Colors.blue,
      isDark,
      700,
      200,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key:'.tr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            translationKey,
            style: TextStyle(
              fontSize: 14,
              color: colors.textColor,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultStringSection(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final colors = _SectionColorHelper.getSectionColors(
      Colors.orange,
      isDark,
      800,
      200,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${defaultLanguage?.name ?? 'Default'.tr}:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
          const SizedBox(height: 4),
          ExpandableText(
            text: defaultText,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultConditionSection(BuildContext context) {
    if (defaultCondition == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final colors = _SectionColorHelper.getSectionColors(
      Colors.orange,
      isDark,
      800,
      200,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${defaultLanguage?.name ?? 'Default'.tr} (${'with Condition'.tr}):',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Param: @{param}'.trP({'param': defaultCondition!.param}),
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          ...defaultCondition!.conditions.entries.map((e) {
            final isDefault = e.key == '_' || e.key == 'default';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDefault
                          ? Colors.orange[200]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDefault
                              ? Colors.orange[900]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ExpandableText(
                        text: e.value.toString(),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTargetStringSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final colors = _SectionColorHelper.getSectionColors(
      Colors.blue,
      isDark,
      800,
      200,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${targetLanguage?.name ?? 'Target'.tr}:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
          const SizedBox(height: 4),
          if (textController != null)
            TextField(
              controller: textController,
              decoration: InputDecoration(
                fillColor: isFlashing ? null : theme.scaffoldBackgroundColor,
                filled: isFlashing ? null : true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: null,
              minLines: 1,
            ),
          const SizedBox(height: 12),
          if (onConvertStringToCondition != null)
            OutlinedButton.icon(
              onPressed: onConvertStringToCondition,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                'Convert to Condition'.tr,
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetConditionSection(BuildContext context) {
    final condition = targetValue as LanguageConditions;

    return InkWell(
      onTap: onEditCondition,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${targetLanguage?.name ?? 'Target'.tr}:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 16, color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Param: @{param}'.trP({'param': condition.param}),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                ...condition.conditions.entries.map((e) {
                  final isDefault = e.key == '_' || e.key == 'default';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDefault
                                ? Colors.blue[200]
                                : Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              e.key,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDefault
                                    ? Colors.blue[900]
                                    : Colors.blue[800],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: ExpandableText(
                              text: e.value.toString(),
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                if (onConvertConditionToString != null)
                  OutlinedButton.icon(
                    onPressed: onConvertConditionToString,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(
                      'Convert to String'.tr,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetOtherSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${targetLanguage?.name ?? 'Target'.tr}:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            targetValue?.toString() ?? 'null'.tr,
            style: TextStyle(fontSize: 14, color: Colors.amber[800]),
          ),
        ],
      ),
    );
  }
}
