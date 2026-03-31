import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum WordLevel { a1, a2, b1, b2, c1, c2 }

enum PartOfSpeech { noun, verb, adjective, adverb, phrase }

enum UiLanguage { ru, ky, both }

extension WordLevelExtension on WordLevel {
  String get label => name.toUpperCase();
}

extension PartOfSpeechExtension on PartOfSpeech {
  String get label => name;
}

@immutable
final class WordTranslation extends Equatable {
  const WordTranslation({
    required this.language,
    required this.translation,
    this.synonyms = const [],
  });

  final String language; // 'ru' or 'ky'
  final String translation;
  final List<String> synonyms;

  @override
  List<Object?> get props => [language, translation, synonyms];
}

@immutable
final class WordExample extends Equatable {
  const WordExample({
    required this.exampleEn,
    this.exampleRu,
    this.exampleKy,
    this.orderIndex = 0,
  });

  final String exampleEn;
  final String? exampleRu;
  final String? exampleKy;
  final int orderIndex;

  @override
  List<Object?> get props => [exampleEn, exampleRu, exampleKy, orderIndex];
}

@immutable
final class Word extends Equatable {
  const Word({
    required this.id,
    required this.word,
    required this.level,
    required this.partOfSpeech,
    required this.createdAt,
    this.transcriptionText,
    this.audioUrl,
    this.imageUrl,
    this.translations = const [],
    this.examples = const [],
  });

  final String id;
  final String word;
  final String? transcriptionText;
  final String? audioUrl;
  final String? imageUrl;
  final WordLevel level;
  final PartOfSpeech partOfSpeech;
  final List<WordTranslation> translations;
  final List<WordExample> examples;
  final DateTime createdAt;

  String? translationFor(String lang) {
    final match = translations.where((t) => t.language == lang);
    return match.isEmpty ? null : match.first.translation;
  }

  @override
  List<Object?> get props => [id, word, level, partOfSpeech];
}
