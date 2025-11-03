import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_improver/language_improver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize LanguageHelper with sample translations
  await LanguageHelper.instance.initial(
    data: [LanguageDataProvider.data(sampleTranslations)],
    initialCode: LanguageCodes.en,
    useInitialCodeWhenUnavailable: false,
  );

  runApp(const MyApp());
}

// Sample translation data
LanguageData sampleTranslations = {
  LanguageCodes.en: {
    'welcome': 'Welcome',
    'hello': 'Hello',
    'goodbye': 'Goodbye',
    'thank_you': 'Thank you',
    'please': 'Please',
    'items_count': const LanguageConditions(
      param: 'count',
      conditions: {'0': 'No items', '1': '1 item', 'default': '@{count} items'},
    ),
    'user_greeting': 'Hello, @{name}!',
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'about': 'About',
    'profile': 'Profile',
    'logout': 'Logout',
  },
  LanguageCodes.vi: {
    'welcome': 'Chào mừng',
    'hello': 'Xin chào',
    'goodbye': 'Tạm biệt',
    'thank_you': 'Cảm ơn',
    'please': 'Xin lỗi',
    'items_count': const LanguageConditions(
      param: 'count',
      conditions: {
        '0': 'Không có mục',
        '1': '1 mục',
        'default': '@{count} mục',
      },
    ),
    'user_greeting': 'Xin chào, @{name}!',
    'settings': 'Cài đặt',
    'language': 'Ngôn ngữ',
    'theme': 'Giao diện',
    'about': 'Giới thiệu',
    'profile': 'Hồ sơ',
    'logout': 'Đăng xuất',
  },
  LanguageCodes.zh: {
    'welcome': '欢迎',
    'hello': '你好',
    'goodbye': '再见',
    'thank_you': '谢谢',
    'please': '请',
    'items_count': const LanguageConditions(
      param: 'count',
      conditions: {'0': '没有项目', '1': '1 项目', 'default': '@{count} 项目'},
    ),
    'user_greeting': '你好, @{name}!',
    'settings': '设置',
    'language': '语言',
    'theme': '主题',
    'about': '关于',
    'profile': '个人资料',
    'logout': '登出',
  },
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Improver Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _lastUpdatedKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Improver Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Language Improver Example',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const Text(
                'This example demonstrates how to use the LanguageImprover widget to edit and improve translations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _openLanguageImprover(context),
                icon: const Icon(Icons.translate),
                label: const Text('Open Language Improver'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    _openLanguageImproverWithSearch(context, 'profile'),
                icon: const Icon(Icons.search),
                label: const Text('Open & Search for "profile"'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openLanguageImproverWithConfig(context),
                icon: const Icon(Icons.settings),
                label: const Text('Open with Custom Config'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              if (_lastUpdatedKey != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated key: $_lastUpdatedKey',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Check the console for full translation updates',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              _buildCurrentLanguageInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLanguageInfo() {
    final helper = LanguageHelper.instance;
    final currentCode = helper.code;

    return Column(
      children: [
        const Text(
          'Current Language',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Code: $currentCode', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          'Available languages: ${helper.codes.join(", ")}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {});
          },
          child: const Text('Refresh Language Info'),
        ),
      ],
    );
  }

  void _openLanguageImprover(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageImprover(
          languageHelper: LanguageHelper.instance,
          onTranslationsUpdated: (updatedTranslations) {
            _handleTranslationsUpdated(context, updatedTranslations);
          },
          onCancel: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Translation editing cancelled'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openLanguageImproverWithSearch(BuildContext context, String key) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageImprover(
          languageHelper: LanguageHelper.instance,
          search: key,
          onTranslationsUpdated: (updatedTranslations) {
            _handleTranslationsUpdated(context, updatedTranslations);
          },
          onCancel: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Translation editing cancelled'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openLanguageImproverWithConfig(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageImprover(
          languageHelper: LanguageHelper.instance,
          initialDefaultLanguage: LanguageCodes.en,
          initialTargetLanguage: LanguageCodes.vi,
          showKey: true,
          onTranslationsUpdated: (updatedTranslations) async {
            // Simulate async save operation
            await Future.delayed(const Duration(milliseconds: 500));
            _handleTranslationsUpdated(context, updatedTranslations);
          },
          onCancel: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Translation editing cancelled'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleTranslationsUpdated(
    BuildContext context,
    Map<LanguageCodes, Map<String, dynamic>> updatedTranslations,
  ) {
    debugPrint('=== Translations Updated ===');
    for (final entry in updatedTranslations.entries) {
      final languageCode = entry.key;
      final translations = entry.value;
      debugPrint('Language: $languageCode');
      debugPrint('Updated translations: $translations');
      debugPrint('Number of keys updated: ${translations.length}');
      debugPrint('');
    }

    // Update UI with the first updated key (if any)
    if (updatedTranslations.isNotEmpty) {
      final firstLanguage = updatedTranslations.keys.first;
      final translations = updatedTranslations[firstLanguage]!;
      if (translations.isNotEmpty) {
        final firstKey = translations.keys.first;
        setState(() {
          _lastUpdatedKey = firstKey;
        });
      }
    }

    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully updated ${updatedTranslations.values.fold<int>(0, (sum, map) => sum + map.length)} translation(s)',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
