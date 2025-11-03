import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

import 'language_condition_editor_dialog.dart';

/// Helper class for conversion between String and LanguageConditions
class TranslationConversion {
  /// Converts a String value to LanguageConditions
  /// Shows dialogs to get parameter name and edit conditions
  static void convertStringToLanguageCondition(
    BuildContext context,
    String key,
    String stringValue,
    LanguageHelper helper,
    LanguageCodes? defaultLanguage,
    Map<String, TextEditingController> controllers,
    Map<String, dynamic> editedTranslations,
    void Function() setState,
  ) {
    // Show dialog to get parameter name first
    showDialog(
      context: context,
      builder: (context) {
        final paramController = TextEditingController(text: 'count');
        bool isDisposed = false;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (_, _) {
            if (!isDisposed) {
              isDisposed = true;
              paramController.dispose();
            }
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Convert to Condition'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the parameter name that will be used in the translation:',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paramController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Parameter Name',
                    hintText: 'e.g., count, number, hours',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    helperText: 'This parameter will be used in conditions',
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;
                    final isDark = colorScheme.brightness == Brightness.dark;
                    final infoBgColor = isDark
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.08);
                    final infoTextColor = isDark
                        ? Colors.blue.shade200
                        : Colors.blue.shade800;
                    final infoBorderColor = isDark
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.blue.withValues(alpha: 0.2);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: infoBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: infoBorderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current value:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: infoTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stringValue,
                            style: TextStyle(
                              fontSize: 12,
                              color: infoTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This will become the default condition (_)',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final param = paramController.text.trim();
                  if (param.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Parameter name cannot be empty'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop();

                  // Create a default LanguageConditions with the current string
                  final newCondition = LanguageConditions(
                    param: param,
                    conditions: {
                      '_': stringValue, // Default condition
                    },
                  );

                  // Get default condition for reference
                  final defaultCondition = defaultLanguage != null
                      ? (helper.data[defaultLanguage]?[key]
                                is LanguageConditions
                            ? helper.data[defaultLanguage]![key]
                                  as LanguageConditions
                            : null)
                      : null;

                  // Show the editor to let user add more conditions
                  showDialog(
                    context: context,
                    builder: (context) => LanguageConditionEditorDialog(
                      key: Key('$key-convert'),
                      translationKey: key,
                      initialCondition: newCondition,
                      defaultCondition: defaultCondition,
                      onSave: (editedCondition) {
                        // Get the controller to dispose later
                        final controllerToDispose = controllers[key];

                        setState();

                        // Remove the controller from the map first
                        controllers.remove(key);

                        // Update to LanguageConditions
                        editedTranslations[key] = editedCondition;

                        // Dispose the controller after the frame completes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          controllerToDispose?.dispose();
                        });

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Converted to Condition successfully',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Converts a LanguageConditions value to String
  /// Shows dialog to select which condition value to use
  static void convertLanguageConditionToString(
    BuildContext context,
    String key,
    LanguageConditions condition,
    Map<String, TextEditingController> controllers,
    Map<String, dynamic> editedTranslations,
    void Function() setState,
  ) {
    // Find the default condition value (_ or default) or use the first one
    String? defaultConditionKey;
    String? defaultConditionValue;

    // Try to find '_' or 'default' first
    if (condition.conditions.containsKey('_')) {
      defaultConditionKey = '_';
      defaultConditionValue = condition.conditions['_']?.toString();
    } else if (condition.conditions.containsKey('default')) {
      defaultConditionKey = 'default';
      defaultConditionValue = condition.conditions['default']?.toString();
    } else if (condition.conditions.isNotEmpty) {
      // Use the first condition if no default found
      final firstEntry = condition.conditions.entries.first;
      defaultConditionKey = firstEntry.key;
      defaultConditionValue = firstEntry.value?.toString();
    }

    if (defaultConditionValue == null || defaultConditionValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid condition value found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show dialog to confirm and optionally choose which condition to use
    showDialog(
      context: context,
      builder: (context) {
        String? selectedKey = defaultConditionKey;
        String? selectedValue = defaultConditionValue;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Convert to String'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select which condition value to use as the string:',
                  ),
                  const SizedBox(height: 12),
                  ...condition.conditions.entries.map((e) {
                    final isDefault =
                        e.key == '_' ||
                        e.key == 'default' ||
                        e.key == selectedKey;
                    return RadioListTile<String>(
                      title: Text(
                        e.key,
                        style: TextStyle(
                          fontWeight: isDefault
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        e.value.toString(),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: e.key,
                      // ignore: deprecated_member_use
                      groupValue: selectedKey,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setDialogState(() {
                          selectedKey = value;
                          selectedValue = e.value?.toString() ?? '';
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedKey == null || selectedValue == null) {
                    return;
                  }
                  Navigator.of(context).pop();

                  // Convert to String
                  setState();

                  // Remove LanguageConditions from edited translations
                  editedTranslations[key] = selectedValue!;

                  // Create a TextEditingController for the new String value
                  final controller = TextEditingController(
                    text: selectedValue!,
                  );
                  controller.addListener(() {
                    editedTranslations[key] = controller.text;
                  });
                  controllers[key] = controller;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Converted to String using condition "$selectedKey"',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Convert'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens the LanguageCondition editor dialog
  static void editLanguageCondition(
    BuildContext context,
    String key,
    LanguageConditions condition,
    LanguageConditions? defaultCondition,
    Map<String, dynamic> editedTranslations,
    void Function() setState,
  ) {
    showDialog(
      context: context,
      builder: (context) => LanguageConditionEditorDialog(
        key: Key(key),
        translationKey: key,
        initialCondition: condition,
        defaultCondition: defaultCondition,
        onSave: (editedCondition) {
          setState();
          editedTranslations[key] = editedCondition;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Condition updated'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
