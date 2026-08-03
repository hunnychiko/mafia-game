import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/word_model.dart';

part 'word_repository.g.dart';

@riverpod
Future<WordRepository> wordRepository(Ref ref) async {
  final raw = await rootBundle.loadString('assets/data/word_bank.json');
  final list = (jsonDecode(raw) as List)
      .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
      .toList();
  return WordRepository(list);
}

class WordQuiz {
  final String word;
  final String correctMeaning;
  final List<String> choices;

  const WordQuiz({
    required this.word,
    required this.correctMeaning,
    required this.choices,
  });
}

class WordRepository {
  WordRepository(this._words)
      : _byWord = {for (final w in _words) w.word.toLowerCase(): w};

  final List<WordModel> _words;
  final Map<String, WordModel> _byWord;

  static final RegExp _englishWordPattern = RegExp(r"^[a-zA-Z]+(?:[-'][a-zA-Z]+)*$");

  bool isEnglishWord(String input) => _englishWordPattern.hasMatch(input.trim());

  WordModel? lookup(String word) => _byWord[word.trim().toLowerCase()];

  WordQuiz buildQuiz(WordModel word, {int choiceCount = 4, Random? random}) {
    final rand = random ?? Random();
    final distractorPool = _words
        .where((w) => w.word != word.word && w.meaning != word.meaning)
        .toList()
      ..shuffle(rand);
    final distractors = distractorPool
        .take(choiceCount - 1)
        .map((w) => w.meaning)
        .toList();

    final choices = [word.meaning, ...distractors]..shuffle(rand);
    return WordQuiz(
      word: word.word,
      correctMeaning: word.meaning,
      choices: choices,
    );
  }
}
