import 'package:flutter/material.dart';

class FieldKey {
  final String key;
  final Color? color;
  final List<String>? suggestions;

  FieldKey({required this.key, this.color, this.suggestions});
}

class FieldPart {
  SegmentType type;
  String text;
  KeyPart? key;

  FieldPart({required this.type, required this.text, this.key});
}

class KeyPart {
  final String key;
  final String? operator;
  final String? value;

  KeyPart({required this.key, this.operator, required this.value});
}

enum SegmentType { text, key }
