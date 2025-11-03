import 'package:language_helper/language_helper.dart';

/// Helper class for translation value retrieval and comparison
class TranslationHelpers {
  /// Gets the default language text for a given key
  static String getDefaultText(
    String key,
    LanguageCodes? defaultLanguage,
    LanguageHelper helper,
  ) {
    if (defaultLanguage == null) return '';

    // Check both dataOverrides and data (overrides take precedence)
    final value =
        helper.dataOverrides[defaultLanguage]?[key] ??
        helper.data[defaultLanguage]?[key];

    if (value == null) return '';
    if (value is String) return value;
    if (value is LanguageConditions) {
      return 'LanguageConditions (${value.conditions.keys.join(', ')})';
    }
    return value.toString();
  }

  /// Gets the target language text for a given key
  static String getTargetText(
    String key,
    LanguageCodes? targetLanguage,
    Map<String, dynamic> editedTranslations,
    LanguageHelper helper,
  ) {
    if (editedTranslations.containsKey(key)) {
      final value = editedTranslations[key];
      if (value is String) return value;
      if (value is LanguageConditions) {
        return 'LanguageConditions (${value.conditions.keys.join(', ')})';
      }
      return value?.toString() ?? '';
    }

    if (targetLanguage == null) return '';

    // Check both dataOverrides and data (overrides take precedence)
    final value =
        helper.dataOverrides[targetLanguage]?[key] ??
        helper.data[targetLanguage]?[key];

    if (value == null) return '';
    if (value is String) return value;
    if (value is LanguageConditions) {
      return 'LanguageConditions (${value.conditions.keys.join(', ')})';
    }
    return value.toString();
  }

  /// Gets the target language value for a given key
  static dynamic getTargetValue(
    String key,
    LanguageCodes? targetLanguage,
    Map<String, dynamic> editedTranslations,
    LanguageHelper helper,
  ) {
    if (editedTranslations.containsKey(key)) {
      return editedTranslations[key];
    }

    if (targetLanguage == null) return null;

    // Check both dataOverrides and data (overrides take precedence)
    return helper.dataOverrides[targetLanguage]?[key] ??
        helper.data[targetLanguage]?[key];
  }

  /// Gets the default language condition for a given key
  static LanguageConditions? getDefaultLanguageCondition(
    String key,
    LanguageCodes? defaultLanguage,
    LanguageHelper helper,
  ) {
    if (defaultLanguage == null) return null;

    // Check both dataOverrides and data (overrides take precedence)
    final value =
        helper.dataOverrides[defaultLanguage]?[key] ??
        helper.data[defaultLanguage]?[key];

    if (value is LanguageConditions) {
      return value;
    }
    return null;
  }

  /// Compare two values to check if they are different
  static bool hasValueChanged(dynamic original, dynamic current) {
    // Handle null cases
    if (original == null && current == null) return false;
    if (original == null || current == null) return true;

    // If types are different, consider it changed (e.g., String -> LanguageConditions)
    if (original.runtimeType != current.runtimeType) return true;

    // Handle String comparison
    if (original is String && current is String) {
      return original != current;
    }

    // Handle LanguageConditions comparison
    if (original is LanguageConditions && current is LanguageConditions) {
      if (original.param != current.param) return true;
      if (original.conditions.length != current.conditions.length) return true;

      // Compare each condition
      for (final entry in original.conditions.entries) {
        final currentValue = current.conditions[entry.key];
        if (currentValue != entry.value) return true;
      }

      // Check for new conditions in current
      for (final entry in current.conditions.entries) {
        if (!original.conditions.containsKey(entry.key)) return true;
      }

      return false;
    }

    // For other types, use equality check
    return original != current;
  }
}

