import 'package:flutter/material.dart';

class TaggedFieldStyle {
  final FieldStyle field;
  final TextStyleConfig text;
  final TagStyle tag;
  final AutocompleteStyle autocomplete;

  const TaggedFieldStyle({
    this.field = const FieldStyle(),
    this.text = const TextStyleConfig(),
    this.tag = const TagStyle(),
    this.autocomplete = const AutocompleteStyle(),
  });
}

class FieldStyle {
  final Border border;
  final Border focusedBorder;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final bool isDense;

  const FieldStyle({
    this.border = const Border.fromBorderSide(
      BorderSide(color: Colors.grey, width: 1.5),
    ),
    this.focusedBorder = const Border.fromBorderSide(
      BorderSide(color: Colors.blueGrey, width: 1.5),
    ),
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.backgroundColor,
    this.isDense = false,
  });
}

class TextStyleConfig {
  final Color? cursorColor;
  final double cursorWidth;
  final TextStyle baseTextStyle;
  final Color? textColor;

  const TextStyleConfig({
    this.cursorColor,
    this.cursorWidth = 1.0,
    this.baseTextStyle = const TextStyle(),
    this.textColor,
  });
}

class TagStyle {
  final Color defaultColor;
  final int opacity;
  final int focusedOpacity;
  final EdgeInsets padding;
  final bool showBorder;
  final double borderWidth;
  final double focusedBorderWidth;
  final double borderRadius;
  final bool useColorForKey;
  final bool useColorForOperator;
  final bool useColorForValue;

  const TagStyle({
    this.defaultColor = Colors.grey,
    this.opacity = 60,
    this.focusedOpacity = 30,
    this.padding = const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0.5),
    this.showBorder = true,
    this.borderWidth = 0.3,
    this.focusedBorderWidth = 0.5,
    this.borderRadius = 4.0,
    this.useColorForKey = true,
    this.useColorForOperator = true,
    this.useColorForValue = false,
  });
}

class AutocompleteStyle {
  final double width;
  final double maxHeight;
  final double itemHeight;
  final EdgeInsets itemPadding;

  const AutocompleteStyle({
    this.width = 200,
    this.maxHeight = 250,
    this.itemHeight = 48,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });
}
