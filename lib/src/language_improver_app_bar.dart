import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

/// AppBar widget for Language Improver with language dropdowns and search
class LanguageImproverAppBar extends PreferredSize {
  final LanguageHelper helper;
  final LanguageCodes? defaultLanguage;
  final LanguageCodes? targetLanguage;
  final TextEditingController searchController;
  final String searchQuery;
  final Future<void> Function(LanguageCodes? value) onDefaultLanguageChanged;
  final Future<void> Function(LanguageCodes? value) onTargetLanguageChanged;

  const LanguageImproverAppBar({
    required this.helper,
    required this.defaultLanguage,
    required this.targetLanguage,
    required this.searchController,
    required this.searchQuery,
    required this.onDefaultLanguageChanged,
    required this.onTargetLanguageChanged,
    super.key,
  }) : super(
         preferredSize: const Size.fromHeight(kToolbarHeight + 120),
         child: const SizedBox.shrink(),
       );

  @override
  Widget build(BuildContext context) {
    return LanguageBuilder(
      builder: (context) {
        return AppBar(
          title: Text('Language Improver'.tr),
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 2,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LanguageDropdown(
                            value: defaultLanguage,
                            labelText: 'Default Language'.tr,
                            items: helper.codes.toList(),
                            onChanged: onDefaultLanguageChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LanguageDropdown(
                            value: targetLanguage,
                            labelText: 'Target Language'.tr,
                            items: helper.codes
                                .where((code) => code != defaultLanguage)
                                .toList(),
                            onChanged: onTargetLanguageChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SearchTextField(
                      controller: searchController,
                      searchQuery: searchQuery,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dropdown widget for language selection
class _LanguageDropdown extends StatelessWidget {
  final LanguageCodes? value;
  final String labelText;
  final List<LanguageCodes> items;
  final Future<void> Function(LanguageCodes? value) onChanged;

  const _LanguageDropdown({
    required this.value,
    required this.labelText,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LanguageCodes>(
      initialValue: value,
      dropdownColor: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      menuMaxHeight: 300,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((code) {
        final isSelected = code == value;
        return DropdownMenuItem(
          value: code,
          child: Text(
            code.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        onChanged(value);
      },
    );
  }
}

/// Search text field widget
class _SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;

  const _SearchTextField({required this.controller, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search translations...'.tr,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
