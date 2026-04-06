import 'package:til1m/domain/entities/word.dart';

final class WordModel extends Word {
  const WordModel({
    required super.id,
    required super.word,
    required super.level,
    required super.partOfSpeech,
    required super.createdAt,
    super.transcriptionText,
    super.audioUrl,
    super.imageUrl,
    super.translations,
    super.examples,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    final translationsRaw = json['word_translations'] as List<dynamic>? ?? [];
    return WordModel(
      id: json['id'] as String,
      word: json['word'] as String,
      level: _parseLevel(json['level'] as String?),
      partOfSpeech: _parsePos(json['part_of_speech'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      transcriptionText: json['transcription_text'] as String?,
      audioUrl: json['audio_url'] as String?,
      imageUrl: json['image_url'] as String?,
      translations: translationsRaw.map((t) {
        final map = t as Map<String, dynamic>;
        return WordTranslation(
          language: map['language'] as String,
          translation: map['translation'] as String,
          synonyms: (map['synonyms'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'level': level.name,
        'part_of_speech': partOfSpeech.name,
        'created_at': createdAt.toIso8601String(),
        'transcription_text': transcriptionText,
        'audio_url': audioUrl,
        'image_url': imageUrl,
        'word_translations': translations
            .map(
              (t) => {
                'language': t.language,
                'translation': t.translation,
                'synonyms': t.synonyms,
              },
            )
            .toList(),
      };

  static WordLevel _parseLevel(String? value) {
    if (value == null) return WordLevel.a1;
    final lower = value.toLowerCase();
    return WordLevel.values.firstWhere(
      (e) => e.name == lower,
      orElse: () => WordLevel.a1,
    );
  }

  static PartOfSpeech _parsePos(String? value) {
    if (value == null) return PartOfSpeech.noun;
    final lower = value.toLowerCase();
    return PartOfSpeech.values.firstWhere(
      (e) => e.name == lower,
      orElse: () => PartOfSpeech.noun,
    );
  }
}
