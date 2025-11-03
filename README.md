# language_improver

A Flutter package that provides a beautiful and intuitive widget for improving translations side-by-side with a reference language. Built on top of the [language_helper](https://pub.dev/packages/language_helper) package.

## Features

- 📝 **Side-by-side comparison**: View default (reference) and target translations together for easy improvement
- 🔍 **Search & filter**: Quickly find translations by key or content with automatic search
- ✏️ **Edit translations**: Inline editing with text fields for each translation
- 🌐 **Multi-language support**: Works with all languages supported by `language_helper`
- 🔢 **LanguageConditions support**: Edit and manage plural forms with `LanguageConditions`
- 💾 **Save & cancel**: Callbacks for handling updated translations and cancellation
- 🎨 **Customizable**: Show/hide translation keys, configure default and target languages

## Getting started

### Prerequisites

This package depends on `language_helper` package. Make sure you have it set up in your project.

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  language_improver: ^0.0.1
  language_helper: ^0.13.0-rc.4
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_improver/language_improver.dart';

class TranslationEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LanguageImprover(
      languageHelper: LanguageHelper.instance,
      onTranslationsUpdated: (updatedTranslations) {
        // Handle the improved translations
        print('Updated translations: $updatedTranslations');
        // You can save these to your storage or update your language files
      },
      onCancel: () {
        // Handle cancellation if needed
        print('Translation editing cancelled');
      },
    );
  }
}
```

### Navigate to Translation Editor

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LanguageImprover(
      languageHelper: LanguageHelper.instance,
      onTranslationsUpdated: (translations) async {
        // Save translations to your storage
        await saveTranslations(translations);
      },
    ),
  ),
);
```

### With Initial Configuration

```dart
LanguageImprover(
  languageHelper: LanguageHelper.instance,
  initialDefaultLanguage: LanguageCodes.en,
  initialTargetLanguage: LanguageCodes.vi,
  search: 'welcome_message', // Automatically searches for this key
  showKey: true,
  onTranslationsUpdated: (translations) {
    // Process updated translations
  },
)
```

### Auto-Search for Specific Key

```dart
LanguageImprover(
  languageHelper: LanguageHelper.instance,
  search: 'hello_world', // Automatically searches for this key
  onTranslationsUpdated: (translations) {
    // Handle updates
  },
)
```

## API Reference

### LanguageImprover Widget

| Parameter | Type | Description |
|-----------|------|-------------|
| `languageHelper` | `LanguageHelper?` | The LanguageHelper instance to use. If not provided, uses `LanguageHelper.instance`. |
| `onTranslationsUpdated` | `FutureOr<void> Function(Map<LanguageCodes, Map<String, dynamic>>)?` | Callback called when translations are saved. Receives updated translations map. Can be async. |
| `onCancel` | `VoidCallback?` | Callback called when the user cancels editing. |
| `initialDefaultLanguage` | `LanguageCodes?` | Initial default/reference language. If not provided, uses first available language. |
| `initialTargetLanguage` | `LanguageCodes?` | Initial target language to improve. If not provided, uses current language. |
| `search` | `String?` | Initial search query. If provided and not empty, the widget will automatically search for keys matching this query. |
| `showKey` | `bool` | Whether to show translation keys. If false, only shows default and target translations. Defaults to `true`. |

## Features in Detail

### Translation Editing

The widget displays translations in a list format with:

- Default/reference language on the left
- Target language (editable) on the right
- Optional translation key display
- Support for both `String` and `LanguageConditions` types

### Search Functionality

Search filters translations by:

- Translation keys
- Translation content (both default and target languages)

When `search` parameter is provided:

- Automatically populates the search field with the query
- Filters the translation list to show matching translations
- Works instantly without requiring user interaction

### LanguageConditions Support

The widget fully supports `LanguageConditions` for handling plural forms:

- Displays condition information
- Allows editing of condition values
- Properly handles condition comparisons when saving

## Additional Information

### Requirements

- Flutter SDK: `>=3.35.0`
- Dart SDK: `^3.9.0`
- `language_helper`: `^0.13.0-rc.4`

### Package Information

- **Version**: 0.0.1
- **Homepage**: <https://github.com/lamnhan066/language_improver>

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

Regenerates the language data by running:

```shell
dart run language_helper:generate --languages=vi,en,es,pt,fr,de,zh,zh_TW,ja,ko,id,ru,it,tr,ar,hi --ignore-todo=en
```

### License

See the [LICENSE](LICENSE) file for details.
