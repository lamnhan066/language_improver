# Language Improver Example

This example demonstrates how to use the `language_improver` package to create a translation editing interface.

## Features Demonstrated

1. **Basic Usage**: Open LanguageImprover with default settings
2. **Scroll to Key**: Automatically scroll to and search for a specific translation key
3. **Custom Configuration**: Configure default language, target language, and other options

## Running the Example

1. Navigate to this directory:

   ```bash
   cd example
   ```

2. Get dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

## What the Example Shows

- **Home Screen**: A simple UI with buttons to open the LanguageImprover in different ways
- **Translation Data**: Sample translations in English, Vietnamese, and Chinese
- **LanguageConditions**: Demonstrates plural form handling with `LanguageConditions`
- **Callbacks**: Shows how to handle `onTranslationsUpdated` and `onCancel` callbacks
- **State Management**: Updates the home screen after translations are saved

## Sample Data

The example includes sample translations for:

- English (en)
- Vietnamese (vi)
- Chinese (zh)

Each language includes simple strings and `LanguageConditions` for plural handling.
