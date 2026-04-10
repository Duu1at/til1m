import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TranslationLanguage {
  ru,
  ky;

  static TranslationLanguage fromCode(String code) => values.firstWhere(
        (e) => e.name == code,
        orElse: () => TranslationLanguage.ru,
      );
}

@immutable
final class Translation extends Equatable {
  const Translation({
    required this.language,
    required this.translation,
    this.synonyms = const [],
  });

  final TranslationLanguage language;
  final String translation;
  final List<String> synonyms;

  @override
  List<Object?> get props => [language, translation, synonyms];
}
