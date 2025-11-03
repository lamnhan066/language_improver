import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

/// Dialog widget for editing LanguageConditions
class LanguageConditionEditorDialog extends StatefulWidget {
  final String translationKey;
  final LanguageConditions initialCondition;
  final void Function(LanguageConditions) onSave;
  final LanguageConditions? defaultCondition;

  const LanguageConditionEditorDialog({
    required this.translationKey,
    required this.initialCondition,
    required this.onSave,
    this.defaultCondition,
    super.key,
  });

  @override
  State<LanguageConditionEditorDialog> createState() =>
      LanguageConditionEditorDialogState();
}

class LanguageConditionEditorDialogState
    extends State<LanguageConditionEditorDialog> {
  late TextEditingController _paramController;
  final Map<String, TextEditingController> _conditionControllers = {};
  final List<String> _conditionKeys = [];

  @override
  void initState() {
    super.initState();
    _paramController = TextEditingController(
      text: widget.initialCondition.param,
    );

    // Initialize condition controllers
    final conditions = widget.initialCondition.conditions;
    for (final entry in conditions.entries) {
      final conditionKey = entry.key;
      _conditionKeys.add(conditionKey);
      _conditionControllers[conditionKey] = TextEditingController(
        text: entry.value.toString(),
      );
    }

    // Sort keys: numeric keys first, then special keys like '_' and 'default'
    _conditionKeys.sort((a, b) {
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);

      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      if (aNum != null) return -1;
      if (bNum != null) return 1;

      // Special keys go last
      if (a == '_' || a == 'default') return 1;
      if (b == '_' || b == 'default') return -1;

      return a.compareTo(b);
    });
  }

  @override
  void dispose() {
    _paramController.dispose();
    for (final controller in _conditionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addCondition() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Add Condition'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter condition key:'.tr),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g., 0, 1, _ or default'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
                helperText: 'Common keys: 0, 1, 2, _ (default)'.tr,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Condition key cannot be empty'.tr),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (_conditionKeys.contains(value)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Condition key "@{key}" already exists'.trP({
                        'key': value,
                      }),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              controller.dispose();
              Navigator.of(context).pop();
              setState(() {
                _conditionKeys.add(value);
                _conditionControllers[value] = TextEditingController();
                // Re-sort to maintain order
                _conditionKeys.sort((a, b) {
                  final aNum = int.tryParse(a);
                  final bNum = int.tryParse(b);

                  if (aNum != null && bNum != null) {
                    return aNum.compareTo(bNum);
                  }
                  if (aNum != null) return -1;
                  if (bNum != null) return 1;

                  if (a == '_' || a == 'default') return 1;
                  if (b == '_' || b == 'default') return -1;

                  return a.compareTo(b);
                });
              });
            },
            child: Text('Add'.tr),
          ),
        ],
      ),
    );
  }

  void _removeCondition(String key) {
    setState(() {
      _conditionKeys.remove(key);
      _conditionControllers[key]?.dispose();
      _conditionControllers.remove(key);
    });
  }

  void _save() {
    if (_paramController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parameter name cannot be empty'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_conditionKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one condition is required'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all conditions have values
    for (final key in _conditionKeys) {
      final controller = _conditionControllers[key];
      if (controller == null || controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Condition "@{key}" cannot be empty'.trP({'key': key}),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Build conditions map
    final conditions = <String, dynamic>{};
    for (final key in _conditionKeys) {
      final controller = _conditionControllers[key]!;
      conditions[key] = controller.text.trim();
    }

    final editedCondition = LanguageConditions(
      param: _paramController.text.trim(),
      conditions: conditions,
    );

    widget.onSave(editedCondition);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Condition'.tr,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.translationKey,
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show default LanguageConditions for reference
                    if (widget.defaultCondition != null) ...[
                      Builder(
                        builder: (context) {
                          final theme = Theme.of(context);
                          final colorScheme = theme.colorScheme;
                          final isDark =
                              colorScheme.brightness == Brightness.dark;
                          final infoBgColor = isDark
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.08);
                          final infoTextColor = isDark
                              ? Colors.orange.shade200
                              : Colors.orange.shade800;
                          final infoBorderColor = isDark
                              ? Colors.orange.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.2);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: infoBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: infoBorderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: infoTextColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Reference (Default Language)'.tr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: infoTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Parameter: @{param}'.trP({
                                    'param': widget.defaultCondition!.param,
                                  }),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: infoTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Conditions:'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: infoTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...widget.defaultCondition!.conditions.entries
                                    .map((e) {
                                      final isDefault =
                                          e.key == '_' || e.key == 'default';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 30,
                                              height: 30,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDefault
                                                    ? Colors.orange[200]
                                                    : Colors.orange[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  e.key,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
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
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.cardColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: theme.dividerColor,
                                                  ),
                                                ),
                                                child: Text(
                                                  e.value.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
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
                        },
                      ),
                    ],
                    // Parameter input
                    TextField(
                      controller: _paramController,
                      decoration: InputDecoration(
                        labelText: 'Parameter Name'.tr,
                        hintText: 'e.g., count, hours, number'.tr,
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
                        helperText:
                            'The parameter used in the translation text'.tr,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Conditions header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Conditions'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addCondition,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('Add Condition'.tr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Conditions list
                    if (_conditionKeys.isEmpty)
                      Builder(
                        builder: (context) {
                          final theme = Theme.of(context);
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Center(
                              child: Text(
                                'No conditions. Add one to get started.'.tr,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      ..._conditionKeys.map((conditionKey) {
                        final controller = _conditionControllers[conditionKey]!;
                        final isDefault =
                            conditionKey == '_' || conditionKey == 'default';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final theme = Theme.of(context);
                                        final colorScheme = theme.colorScheme;
                                        final isDark =
                                            colorScheme.brightness ==
                                            Brightness.dark;
                                        final badgeBgColor = isDefault
                                            ? (isDark
                                                  ? Colors.blue.withValues(
                                                      alpha: 0.3,
                                                    )
                                                  : Colors.blue.shade100)
                                            : (isDark
                                                  ? Colors.green.withValues(
                                                      alpha: 0.3,
                                                    )
                                                  : Colors.green.shade100);
                                        final badgeTextColor = isDefault
                                            ? (isDark
                                                  ? Colors.blue.shade200
                                                  : Colors.blue.shade900)
                                            : (isDark
                                                  ? Colors.green.shade200
                                                  : Colors.green.shade900);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBgColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            conditionKey,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: badgeTextColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (isDefault) ...[
                                      const SizedBox(width: 8),
                                      Builder(
                                        builder: (context) {
                                          final theme = Theme.of(context);
                                          final colorScheme = theme.colorScheme;
                                          final isDark =
                                              colorScheme.brightness ==
                                              Brightness.dark;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.blue.withValues(
                                                      alpha: 0.3,
                                                    )
                                                  : Colors.blue.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'DEFAULT'.tr,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.blue.shade200
                                                    : Colors.blue.shade900,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red,
                                      onPressed: () =>
                                          _removeCondition(conditionKey),
                                      tooltip: 'Remove Condition'.tr,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Translation Value'.tr,
                                    hintText:
                                        'Enter translation for this condition'
                                            .tr,
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    helperText: isDefault
                                        ? 'Used when no other condition matches'
                                              .tr
                                        : null,
                                  ),
                                  maxLines: null,
                                  minLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      top: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: colorScheme.outline,
                            width: 1.5,
                          ),
                          foregroundColor: colorScheme.outline,
                          backgroundColor: theme.scaffoldBackgroundColor,
                        ),
                        child: Text('Cancel'.tr),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save, size: 20),
                        label: Text('Save'.tr),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
