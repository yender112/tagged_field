import 'key_model.dart';

abstract class FieldSegment {
  int get length;
  String toText();
}

class TextSegment extends FieldSegment {
  String text;
  TextSegment(this.text);

  @override
  int get length => text.length;

  @override
  String toText() => text;
}

class ChipSegment extends FieldSegment {
  KeyMatch key;

  ChipSegment({required this.key});

  @override
  int get length => toText().length;

  @override
  String toText() => '${key.key}${key.operator}${key.value}';
}
