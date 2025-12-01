import 'package:flutter/material.dart';

/// Represents a recognized key that can be used to create tags.
class FieldKey {
  final String key;
  final Color? color;
  final List<String>? suggestions;

  FieldKey({required this.key, this.color, this.suggestions});
}

/// A parsed segment of the input field content.
class FieldPart {
  SegmentType type;
  String text;
  KeyPart? key;

  FieldPart({required this.type, required this.text, this.key});
}

/// The structured components of a key-value tag (e.g., "status:open").
class KeyPart {
  final String key;
  final String? operator;
  final String? value;

  KeyPart({required this.key, this.operator, required this.value});
}

/// Identifies whether a segment is plain text or a recognized key tag.
enum SegmentType { text, key }
