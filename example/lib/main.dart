import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tagged_field/tagged_field.dart';

part 'demo/boilerplate.dart';

TaggedField basicUsageExample() {
  return TaggedField(
    recognizedKeys: [
      FieldKey(
        key: 'status',
        color: Colors.blue,
        suggestions: ['open', 'closed', 'pending'],
      ),
      FieldKey(
        key: 'priority',
        color: Colors.red,
        suggestions: ['high', 'medium', 'low'],
      ),
      FieldKey(
        key: 'author',
        color: Colors.green,
        suggestions: ['john', 'jane', 'admin'],
      ),
    ],
  );
}

TaggedField monospaceEmaple() {
  return TaggedField(
    recognizedKeys: [
      FieldKey(
        key: 'file',
        color: Colors.deepPurple,
        suggestions: ['main.dart', 'pubspec.yaml'],
      ),
      FieldKey(
        key: 'line',
        color: Colors.pink,
        suggestions: ['1', '10', '100'],
      ),
      FieldKey(
        key: 'col',
        color: Colors.indigo,
        suggestions: ['1', '20', '80'],
      ),
    ],
    style: TaggedFieldStyle(
      field: FieldStyle(borderRadius: BorderRadius.all(Radius.circular(8))),
      text: TextStyleConfig(
        baseTextStyle: GoogleFonts.robotoMono(fontSize: 14),
      ),
      tag: TagStyle(
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2.5),
      ),
    ),
  );
}

TaggedField searchBarExample() {
  return TaggedField(
    recognizedKeys: [
      FieldKey(
        key: 'type',
        color: Colors.indigo,
        suggestions: ['email', 'document', 'image'],
      ),
      FieldKey(
        key: 'from',
        color: Colors.cyan,
        suggestions: ['team', 'external', 'me'],
      ),
      FieldKey(
        key: 'has',
        color: Colors.pink,
        suggestions: ['attachment', 'link', 'image'],
      ),
      FieldKey(
        key: 'date',
        color: Colors.amber,
        suggestions: ['today', 'week', 'month'],
      ),
    ],
    behavior: const TaggedFieldBehavior(
      excludeTagsFromSubmitQuery: true,
      excludeQueryFromSubmitTags: true,
    ),
    style: TaggedFieldStyle(
      field: FieldStyle(
        borderRadius: BorderRadius.circular(40),
        focusedBorder: Border.all(color: Colors.red, width: 2),
      ),
      text: TextStyleConfig(
        baseTextStyle: GoogleFonts.robotoMono(fontWeight: FontWeight.w500),
        cursorColor: Colors.indigo,
      ),
      tag: const TagStyle(
        opacity: 55,
        showBorder: true,
        padding: EdgeInsets.all(2),
      ),
    ),
  );
}

TaggedField compactExample() {
  return TaggedField(
    recognizedKeys: [
      FieldKey(
        key: 'tag',
        color: Colors.teal,
        suggestions: ['flutter', 'dart', 'mobile'],
      ),
      FieldKey(
        key: 'lang',
        color: Colors.cyan,
        suggestions: ['en', 'es', 'fr'],
      ),
    ],
    style: TaggedFieldStyle(
      field: FieldStyle(
        isDense: true,
        borderRadius: BorderRadius.circular(4),
        focusedBorder: Border.all(color: Colors.teal, width: 1.5),
      ),
      text: const TextStyleConfig(baseTextStyle: TextStyle(fontSize: 13)),
      tag: const TagStyle(borderRadius: 4, opacity: 40),
    ),
  );
}
