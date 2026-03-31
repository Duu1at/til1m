import 'package:equatable/equatable.dart';

enum WordLevel { a1, a2, b1, b2, c1, c2 }

enum PartOfSpeech { noun, verb, adjective, adverb, phrase }

enum UiLanguage { ru, ky, both }

extension WordLevelExtension on WordLevel {
  String get label => name.toUpperCase();
}

extension PartOfSpeechExtension on PartOfSpeech {
  String get label => name;
}

class WordTranslation extends Equatable {
  final String language; // 'ru' or 'ky'
  final String translation;
  final List<String> synonyms;

  const WordTranslation({
    required this.language,
    required this.translation,
    this.synonyms = const [],
  });

  @override
  List<Object?> get props => [language, translation, synonyms];
}

class WordExample extends Equatable {
  final String exampleEn;
  final String? exampleRu;
  final String? exampleKy;
  final int orderIndex;

  const WordExample({
    required this.exampleEn,
    this.exampleRu,
    this.exampleKy,
    this.orderIndex = 0,
  });

  @override
  List<Object?> get props => [exampleEn, exampleRu, exampleKy, orderIndex];
}

class Word extends Equatable {
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

  const Word({
    required this.id,
    required this.word,
    this.transcriptionText,
    this.audioUrl,
    this.imageUrl,
    required this.level,
    required this.partOfSpeech,
    this.translations = const [],
    this.examples = const [],
    required this.createdAt,
  });

  String? translationFor(String lang) {
    try {
      return translations.firstWhere((t) => t.language == lang).translation;
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, word, level, partOfSpeech];
}
