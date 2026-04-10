import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:til1m/domain/entities/translation.dart';
import 'package:til1m/domain/entities/word_example.dart';
export 'package:til1m/domain/entities/translation.dart';
export 'package:til1m/domain/entities/word_example.dart';

enum WordLevel { a1, a2, b1, b2, c1, c2 }

enum PartOfSpeech { noun, verb, adjective, adverb, phrase }

enum UiLanguage { ru, ky, both }

extension WordLevelExtension on WordLevel {
  String get label => name.toUpperCase();
}

extension PartOfSpeechExtension on PartOfSpeech {
  String get label => name;
}

typedef WordTranslation = Translation;

@immutable
class Word extends Equatable {
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
  final List<Translation> translations;
  final List<WordExample> examples;
  final DateTime createdAt;

  String? translationFor(String lang) {
    final language = TranslationLanguage.fromCode(lang);
    final match = translations.where((t) => t.language == language);
    return match.isEmpty ? null : match.first.translation;
  }

  @override
  List<Object?> get props => [id, word, level, partOfSpeech];
}
