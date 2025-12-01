import '../models/models.dart';

class KeyMatch {
  final int start;
  final int end;
  final FieldKey key;
  final String operator;
  final int valueStart;
  final String? value;

  String get text {
    return "${key.key}$operator$value";
  }

  KeyMatch({
    required this.start,
    required this.end,
    required this.key,
    required this.operator,
    required this.valueStart,
    this.value,
  });
}

class Suggestion {
  String word;
  WordIndex wordOrigin;
  String? description;

  Suggestion({required this.word, required this.wordOrigin, this.description});
}

class WordIndex {
  WordType type;
  String word;
  int startIndex;
  int endIndex;
  KeyMatch? key;

  WordIndex({
    required this.type,
    required this.word,
    required this.startIndex,
    required this.endIndex,
    this.key,
  });
}

enum WordType {
  unknown, // No tag and no value of any tag
  blank, // Blank space, viable to add a tag
  partialWord,
  valueOfKey, // Value of a existing tag
}
