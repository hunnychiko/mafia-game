class WordModel {
  final String word;
  final String meaning;
  final String pos;

  const WordModel({
    required this.word,
    required this.meaning,
    required this.pos,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      pos: json['pos'] as String? ?? '',
    );
  }
}
