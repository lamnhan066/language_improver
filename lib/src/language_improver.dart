import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

import 'language_improver_app_bar.dart';
import 'translation_card.dart';
import 'translation_conversion.dart';
import 'translation_helpers.dart';

/// A stateful widget to list all translations and improve them
/// based on a default language reference.
///
/// This widget allows users to:
/// - Select a default/reference language
/// - View all translations side-by-side with the reference
/// - Edit and improve translations
/// - Receive improved translations via callback
///
/// Example usage:
/// ```dart
/// LanguageImprover(
///   languageHelper: LanguageHelper.instance,
///   onTranslationsUpdated: (updatedTranslations) {
///     // Handle the improved translations
///     print('Updated translations: $updatedTranslations');
///   },
/// )
/// ```
class LanguageImprover extends StatefulWidget {
  /// The LanguageHelper instance to use.
  /// If not provided, uses [LanguageHelper.instance].
  final LanguageHelper? languageHelper;

  /// Callback called when translations are updated.
  /// Receives a map of [LanguageCodes] to updated translations.
  /// Can return a Future to be awaited before popping the screen.
  final FutureOr<void> Function(Map<LanguageCodes, Map<String, dynamic>>)?
  onTranslationsUpdated;

  /// Callback called when the user cancels editing.
  final VoidCallback? onCancel;

  /// Initial default language code.
  /// If not provided, uses the first available language.
  final LanguageCodes? initialDefaultLanguage;

  /// Initial target language code to improve.
  /// If not provided, uses the current language.
  final LanguageCodes? initialTargetLanguage;

  /// Initial key to scroll to and focus on.
  /// If provided, the widget will automatically scroll to this key and
  /// optionally filter/search for it.
  final String? scrollToKey;

  /// Whether to automatically search for the [scrollToKey] when provided.
  /// Defaults to true.
  final bool autoSearchOnScroll;

  /// Whether to show the translation key. If false, only shows default and target translations.
  /// Defaults to true.
  final bool showKey;

  const LanguageImprover({
    super.key,
    this.languageHelper,
    this.onTranslationsUpdated,
    this.onCancel,
    this.initialDefaultLanguage,
    this.initialTargetLanguage,
    this.scrollToKey,
    this.autoSearchOnScroll = true,
    this.showKey = true,
  });

  @override
  State<LanguageImprover> createState() => _LanguageImproverState();
}

class _LanguageImproverState extends State<LanguageImprover>
    with TickerProviderStateMixin {
  late LanguageHelper _helper;
  LanguageCodes? _defaultLanguage;
  LanguageCodes? _targetLanguage;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _editedTranslations = {};
  final Map<String, dynamic> _originalTranslations = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _allKeys = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _keyMap = {};
  AnimationController? _flashAnimationController;
  Animation<double>? _flashAnimation;
  String? _flashingKey;
  int _flashRepeatCount = 0;
  static const int _maxFlashRepeats = 10;

  @override
  void initState() {
    super.initState();
    _helper = widget.languageHelper ?? LanguageHelper.instance;

    // Initialize flash animation controller (faster animation)
    _flashAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.6,
      ),
    ]).animate(_flashAnimationController!);

    _flashAnimationController!.addListener(() {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update animation
        });
      }
    });

    // Handle animation completion for repeating
    _flashAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _handleFlashAnimationComplete();
      }
    });

    // Get all available languages and keys
    _initializeLanguages().then((_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild after data is loaded
        });

        // After data is loaded and widget rebuilt, scroll to key
        if (widget.scrollToKey != null) {
          // Pre-create the key in the map
          final targetKey = widget.scrollToKey!;
          if (!_keyMap.containsKey(targetKey)) {
            _keyMap[targetKey] = GlobalKey();
          }

          // Wait for multiple frames to ensure ListView is fully built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _attemptScrollToKey();
            }
          });
        }
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });

      // Scroll to target key if it matches the search
      if (widget.scrollToKey != null &&
          _filteredKeys.contains(widget.scrollToKey)) {
        // Wait for the ListView to rebuild with filtered results
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _scrollToKey(widget.scrollToKey!);
            }
          });
        });
      }
    });

    // Set search text if scrollToKey is provided and autoSearchOnScroll is true
    if (widget.scrollToKey != null && widget.autoSearchOnScroll) {
      // This will be set after data loads in _initializeLanguages
    }
  }

  void _scrollToKey(String targetKey) {
    // Wait for ScrollController to be attached
    void tryScrollWithController({int retryCount = 0}) {
      if (!mounted) return;

      // First, try to find the index of the target key in filtered keys
      final index = _filteredKeys.indexOf(targetKey);

      if (index >= 0 && _scrollController.hasClients) {
        // Calculate approximate position based on index
        // Estimate card height: padding (8*2) + margin (8*2) + card height (~200)
        const estimatedCardHeight = 250.0; // Approximate height per card
        final estimatedPosition = index * estimatedCardHeight;

        // Clamp position to valid range
        final maxScroll = _scrollController.position.maxScrollExtent;
        final scrollPosition = estimatedPosition.clamp(0.0, maxScroll);

        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );

        // After scrolling, try to use ensureVisible for precise positioning
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _scrollToKeyPrecise(targetKey);
          }
        });
      } else if (retryCount < 5) {
        // ScrollController not ready yet, retry
        Future.delayed(Duration(milliseconds: 100 + (retryCount * 50)), () {
          tryScrollWithController(retryCount: retryCount + 1);
        });
      } else {
        // Fallback to precise scrolling if controller never becomes ready
        _scrollToKeyPrecise(targetKey);
      }
    }

    tryScrollWithController();
  }

  /// Precise scrolling using Scrollable.ensureVisible
  void _scrollToKeyPrecise(String targetKey) {
    // Create the key if it doesn't exist yet
    if (!_keyMap.containsKey(targetKey)) {
      _keyMap[targetKey] = GlobalKey();
    }

    final globalKey = _keyMap[targetKey];

    // Wait for the widget to be built and context to be available
    void tryScroll({int retryCount = 0}) {
      if (!mounted) return;

      if (globalKey?.currentContext != null) {
        try {
          Scrollable.ensureVisible(
            globalKey!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.1, // Position slightly from top for better visibility
          );

          // Trigger flash animation when key becomes visible
          _triggerFlashAnimation(targetKey);
        } catch (e) {
          // If scroll fails, retry up to 3 times
          if (retryCount < 3) {
            Future.delayed(const Duration(milliseconds: 200), () {
              tryScroll(retryCount: retryCount + 1);
            });
          }
        }
      } else {
        // Context not available yet, retry up to 5 times
        if (retryCount < 5) {
          Future.delayed(Duration(milliseconds: 200 + (retryCount * 100)), () {
            tryScroll(retryCount: retryCount + 1);
          });
        }
      }
    }

    // Start trying to scroll
    tryScroll();
  }

  Future<void> _initializeLanguages() async {
    final codes = _helper.codes.toList();
    if (codes.isEmpty) return;

    // Set default language
    _defaultLanguage = widget.initialDefaultLanguage ?? codes.first;
    if (!codes.contains(_defaultLanguage)) {
      _defaultLanguage = codes.first;
    }

    // Set target language
    _targetLanguage = widget.initialTargetLanguage ?? _helper.code;
    if (!codes.contains(_targetLanguage) ||
        _targetLanguage == _defaultLanguage) {
      _targetLanguage = codes.firstWhere(
        (code) => code != _defaultLanguage,
        orElse: () => codes.first,
      );
    }

    // Ensure data is loaded for both default and target languages
    if (_defaultLanguage != null) {
      final defaultLang = _defaultLanguage!;
      await _ensureDataLoaded(defaultLang);
    }
    if (_targetLanguage != null) {
      final targetLang = _targetLanguage!;
      await _ensureDataLoaded(targetLang);
    }

    // Collect all keys from all available languages
    // Check both data and dataOverrides
    _allKeys.clear();
    for (final code in codes) {
      await _ensureDataLoaded(code);

      // Check both data and dataOverrides
      final data = _helper.data[code];
      final dataOverrides = _helper.dataOverrides[code];

      if (data != null) {
        _allKeys.addAll(data.keys);
      }
      if (dataOverrides != null) {
        _allKeys.addAll(dataOverrides.keys);
      }
    }

    // If no keys found, try to get them from the current language
    if (_allKeys.isEmpty) {
      await _ensureDataLoaded(_helper.code);
      final currentData = _helper.data[_helper.code];
      final currentOverrides = _helper.dataOverrides[_helper.code];
      if (currentData != null) {
        _allKeys.addAll(currentData.keys);
      }
      if (currentOverrides != null) {
        _allKeys.addAll(currentOverrides.keys);
      }
    }

    _allKeys.removeWhere((key) => key.startsWith('@path_'));

    // Initialize controllers and edited translations
    _initializeControllers();

    // Set search text if scrollToKey is provided and autoSearchOnScroll is true
    if (widget.scrollToKey != null &&
        widget.autoSearchOnScroll &&
        _allKeys.contains(widget.scrollToKey)) {
      _searchController.text = widget.scrollToKey!;
    }
  }

  /// Attempt to scroll to the target key
  void _attemptScrollToKey() {
    if (widget.scrollToKey == null) return;

    final targetKey = widget.scrollToKey!;

    // If key is not in all keys, can't scroll to it
    if (!_allKeys.contains(targetKey)) {
      return;
    }

    // If key is not in the filtered keys, try to filter first
    if (!_filteredKeys.contains(targetKey)) {
      if (widget.autoSearchOnScroll) {
        // Set search to show the key
        _searchController.text = targetKey;
        // Wait for filtering to complete and widget to rebuild
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToKey(targetKey);
          }
        });
      }
      return;
    }

    // Key should be visible, wait for ListView to build the item
    // We need to wait for the widget to actually be built in the ListView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToKey(targetKey);
      }
    });
  }

  /// Ensure data is loaded for a specific language code
  Future<void> _ensureDataLoaded(LanguageCodes code) async {
    // Check if data is already loaded
    if (_helper.data.containsKey(code) ||
        _helper.dataOverrides.containsKey(code)) {
      return;
    }

    // Data might not be loaded yet, try to load it by changing to that code
    // This will trigger the data loading in the change method
    // But we need to restore the current code after
    final currentCode = _helper.code;
    if (currentCode != code) {
      await _helper.change(code);
      // Restore original code if needed (optional, as we'll use the loaded data)
      // Actually, we don't need to restore, just ensure data is loaded
    }
  }

  void _initializeControllers() {
    _controllers.clear();
    _editedTranslations.clear();
    _originalTranslations.clear();

    if (_targetLanguage == null) return;

    // Check both data and dataOverrides (overrides take precedence)
    final targetData =
        _helper.dataOverrides[_targetLanguage] ?? _helper.data[_targetLanguage];
    if (targetData == null) return;

    for (final key in _allKeys) {
      // Get value from overrides first, then data
      final value =
          _helper.dataOverrides[_targetLanguage]?[key] ??
          _helper.data[_targetLanguage]?[key];

      if (value is String) {
        // Handle empty strings - they are valid values
        final controller = TextEditingController(text: value);
        controller.addListener(() {
          _editedTranslations[key] = controller.text;
        });
        _controllers[key] = controller;
        _editedTranslations[key] = value;
        // Store original value for comparison
        _originalTranslations[key] = value;
      } else if (value is LanguageConditions) {
        // Store LanguageConditions as-is for editing
        // For LanguageConditions, we need to store a deep copy for comparison
        _editedTranslations[key] = value;
        _originalTranslations[key] = LanguageConditions(
          param: value.param,
          conditions: Map<String, dynamic>.from(value.conditions),
        );
      } else if (value != null) {
        // For other types, store as-is
        _editedTranslations[key] = value;
        _originalTranslations[key] = value;
      }
      // If value is null, don't add it to editedTranslations
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    _scrollController.dispose();
    _flashAnimationController?.dispose();
    super.dispose();
  }

  /// Trigger flash animation for a specific key
  void _triggerFlashAnimation(String key) {
    if (!mounted) return;

    setState(() {
      _flashingKey = key;
      _flashRepeatCount = 0;
    });

    // Start the first flash
    _flashAnimationController?.reset();
    _flashAnimationController?.forward();
  }

  /// Handle flash animation completion - repeat if needed
  void _handleFlashAnimationComplete() {
    if (!mounted || _flashingKey == null) return;

    _flashRepeatCount++;

    if (_flashRepeatCount < _maxFlashRepeats) {
      // Repeat the animation
      _flashAnimationController?.reset();
      _flashAnimationController?.forward();
    } else {
      // Stop after max repeats
      _stopFlashAnimation();
    }
  }

  /// Stop the flash animation
  void _stopFlashAnimation() {
    if (!mounted) return;

    _flashAnimationController?.stop();
    _flashAnimationController?.reset();

    setState(() {
      _flashingKey = null;
      _flashRepeatCount = 0;
    });
  }

  /// Handle tap on the flashing card to stop animation
  void _onCardTap(String key) {
    if (_flashingKey == key) {
      _stopFlashAnimation();
    }
  }

  List<String> get _filteredKeys {
    if (_searchQuery.isEmpty) return _allKeys.toList();

    return _allKeys.where((key) {
      final defaultText = TranslationHelpers.getDefaultText(
        key,
        _defaultLanguage,
        _helper,
      );
      final targetText = TranslationHelpers.getTargetText(
        key,
        _targetLanguage,
        _editedTranslations,
        _helper,
      );
      return key.toLowerCase().contains(_searchQuery) ||
          defaultText.toLowerCase().contains(_searchQuery) ||
          targetText.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _saveTranslations() async {
    // Only include translations that have actually changed
    final changedTranslations = <String, dynamic>{};

    for (final entry in _editedTranslations.entries) {
      final key = entry.key;
      final currentValue = entry.value;
      final originalValue = _originalTranslations[key];

      // Check if the value has changed
      if (TranslationHelpers.hasValueChanged(originalValue, currentValue)) {
        changedTranslations[key] = currentValue;
      }
    }

    // If no changes were made, show message and return
    if (changedTranslations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No changes to save'.tr),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final updatedTranslations = <LanguageCodes, Map<String, dynamic>>{
      _targetLanguage!: changedTranslations,
    };

    // Call the callback and wait for it to complete if it's async
    final callback = widget.onTranslationsUpdated;
    if (callback != null) {
      await callback(updatedTranslations);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '@{count} translation@{plural} saved successfully'.trP({
              'count': changedTranslations.length.toString(),
              'plural': changedTranslations.length == 1 ? '' : 's',
            }),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Pop the screen after translations are applied
      Navigator.of(context).pop();
    }
  }

  void _cancelEditing() {
    _initializeControllers();
    widget.onCancel?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Changes discarded'.tr),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  void _convertStringToLanguageCondition(String key, String stringValue) {
    TranslationConversion.convertStringToLanguageCondition(
      context,
      key,
      stringValue,
      _helper,
      _defaultLanguage,
      _controllers,
      _editedTranslations,
      () => setState(() {}),
    );
  }

  void _convertLanguageConditionToString(
    String key,
    LanguageConditions condition,
  ) {
    TranslationConversion.convertLanguageConditionToString(
      context,
      key,
      condition,
      _controllers,
      _editedTranslations,
      () => setState(() {}),
    );
  }

  void _editLanguageCondition(String key, LanguageConditions condition) {
    final defaultCondition = TranslationHelpers.getDefaultLanguageCondition(
      key,
      _defaultLanguage,
      _helper,
    );
    TranslationConversion.editLanguageCondition(
      context,
      key,
      condition,
      defaultCondition,
      _editedTranslations,
      () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_helper.codes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Language Improver'.tr),
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
        ),
        body: Center(child: Text('No languages available'.tr)),
      );
    }

    return Scaffold(
      appBar: LanguageImproverAppBar(
        helper: _helper,
        defaultLanguage: _defaultLanguage,
        targetLanguage: _targetLanguage,
        searchController: _searchController,
        searchQuery: _searchQuery,
        onDefaultLanguageChanged: (value) async {
          if (value != null && value != _targetLanguage) {
            // Ensure data is loaded for the default language
            if (!_helper.data.containsKey(value)) {
              final currentCode = _helper.code;
              // Load data for the default language
              await _helper.change(value);
              // Restore original language if it was different
              if (currentCode != value) {
                await _helper.change(currentCode);
              }
            }
            setState(() {
              _defaultLanguage = value;
            });
          }
        },
        onTargetLanguageChanged: (value) async {
          if (value != null) {
            // Ensure data is loaded for the target language
            if (!_helper.data.containsKey(value)) {
              final currentCode = _helper.code;
              // Load data for the target language
              await _helper.change(value);
              // Restore original language if it was different
              if (currentCode != value) {
                await _helper.change(currentCode);
              }
            }
            setState(() {
              _targetLanguage = value;
              _initializeControllers();
            });
          }
        },
      ),
      body: _filteredKeys.isEmpty
          ? Center(child: Text('No translations found'.tr))
          : Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 8,
                  right: 8,
                  bottom: 80,
                ),
                itemCount: _filteredKeys.length,
                itemBuilder: (context, index) {
                  final key = _filteredKeys[index];
                  final defaultText = TranslationHelpers.getDefaultText(
                    key,
                    _defaultLanguage,
                    _helper,
                  );
                  final targetValue = TranslationHelpers.getTargetValue(
                    key,
                    _targetLanguage,
                    _editedTranslations,
                    _helper,
                  );

                  // Create or get GlobalKey for this translation key
                  if (!_keyMap.containsKey(key)) {
                    _keyMap[key] = GlobalKey();
                  }
                  final cardKey = _keyMap[key]!;

                  // Get flash animation value if this key is flashing
                  final isFlashing = _flashingKey == key;
                  final flashValue = isFlashing && _flashAnimation != null
                      ? _flashAnimation!.value
                      : 0.0;

                  return TranslationCard(
                    key: cardKey,
                    cardKey: cardKey,
                    translationKey: key,
                    defaultText: defaultText,
                    targetValue: targetValue,
                    showKey: widget.showKey,
                    isFlashing: isFlashing,
                    flashValue: flashValue,
                    defaultLanguage: _defaultLanguage,
                    targetLanguage: _targetLanguage,
                    textController: _controllers[key],
                    defaultCondition:
                        TranslationHelpers.getDefaultLanguageCondition(
                          key,
                          _defaultLanguage,
                          _helper,
                        ),
                    onCardTap: () => _onCardTap(key),
                    onConvertStringToCondition: targetValue is String
                        ? () => _convertStringToLanguageCondition(
                            key,
                            targetValue,
                          )
                        : null,
                    onConvertConditionToString:
                        targetValue is LanguageConditions
                        ? () => _convertLanguageConditionToString(
                            key,
                            targetValue,
                          )
                        : null,
                    onEditCondition: targetValue is LanguageConditions
                        ? () => _editLanguageCondition(key, targetValue)
                        : null,
                  );
                },
              ),
            ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _cancelEditing,
              icon: const Icon(Icons.close, size: 20),
              label: Text(
                'Cancel'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1.5,
                ),
                foregroundColor: Theme.of(context).colorScheme.outline,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _saveTranslations,
              icon: const Icon(Icons.save, size: 20),
              label: Text(
                'Save'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
