import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/behavior.dart';
import 'models/models.dart';
import 'models/style.dart';

/// A Flutter TextField with inline tag recognition, autocomplete suggestions,
/// and real-time chip visualization for `key=value` syntax.
class TaggedField extends StatefulWidget {
  /// Keys the field will recognize and render as chips.
  final List<FieldKey> recognizedKeys;

  /// Called when the user submits (Enter key). Provides:
  /// - `query`: free text (excludes tags if [TaggedFieldBehavior.excludeTagsFromSubmitQuery] is true)
  /// - `parts`: parsed segments including recognized key-value tags
  final Function(String query, List<FieldPart> parts)? onSubmitted;

  /// Visual customization: field borders, text style, tag chips, and autocomplete dropdown.
  final TaggedFieldStyle style;

  /// Controls duplicate keys handling and submit output separation.
  final TaggedFieldBehavior behavior;

  /// Optional external focus node for programmatic focus control.
  final FocusNode? focusNode;

  /// If true, field retains focus after submission; otherwise unfocuses.
  final bool keepFocusedOnSubmit;

  const TaggedField({
    super.key,
    required this.recognizedKeys,
    this.onSubmitted,
    this.style = const TaggedFieldStyle(),
    this.behavior = const TaggedFieldBehavior(),
    this.focusNode,
    this.keepFocusedOnSubmit = true,
  });

  @override
  State<TaggedField> createState() => _TaggedFieldState();
}

class _TaggedFieldState extends State<TaggedField> {
  late FocusNode _focusNode;
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final ScrollController _textScrollController = ScrollController();
  final ScrollController _autocompleteScrollController = ScrollController();
  OverlayEntry? _autocompleteMenu;

  List<_FieldSegment> _segments = [_TextSegment('')];
  List<FieldPart> _parts = [];
  String _text = "";

  static const double _letterSpacing = 0.0;
  static const double _standardHeigth = 48;
  static const double _denseHeigth = 40;
  static const double _defaultFontSize = 14;

  List<_Suggestion> _filteredSuggestions = [];
  String _previusText = "";
  bool _isSelecting = false;
  int _selectedIndex = -1;
  int _baseOffset = 0;
  int _extentOffset = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _textScrollController.dispose();
    _autocompleteScrollController.dispose();
    _hideAutocomplete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.style.field.backgroundColor ??
        Theme.of(context).colorScheme.surface;

    final bool isDense = widget.style.field.isDense;
    final double heigth = isDense ? _denseHeigth : _standardHeigth;
    final double verticalPadding = (heigth / 4) - 2;
    final double horizontalPadding = heigth / 4;
    final double overlayHeight = heigth / 2;

    final fontSize =
        widget.style.text.baseTextStyle.fontSize ?? _defaultFontSize;
    final double offsetCorrection = isDense
        ? ((fontSize / (fontSize / 8)) + (kIsWeb ? 0 : 4)) * -1
        : 0;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints.tight(Size.fromHeight(heigth)),
          decoration: BoxDecoration(
            border: _focusNode.hasFocus
                ? widget.style.field.focusedBorder
                : widget.style.field.border,
            borderRadius: widget.style.field.borderRadius,
            color: backgroundColor,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is UserScrollNotification) {
                    _hideAutocomplete();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _textScrollController,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: IntrinsicWidth(
                      child: Stack(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              selectAllOnFocus: false,
                              style: _getTextStyle(color: Colors.transparent),
                              cursorColor: widget.style.text.cursorColor,
                              cursorWidth: widget.style.text.cursorWidth,
                              textAlignVertical: isDense
                                  ? TextAlignVertical.center
                                  : TextAlignVertical.top,
                              onSubmitted: (value) {
                                widget.onSubmitted!(_text, _parts);
                                _hideAutocomplete();
                              },
                              decoration: InputDecoration(
                                isDense: isDense,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: isDense
                                      ? offsetCorrection
                                      : verticalPadding,
                                ),
                                constraints: BoxConstraints(
                                  maxHeight: heigth,
                                  minHeight: heigth,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),

                          Positioned(
                            left: horizontalPadding,
                            top: verticalPadding + 2,
                            child: SizedBox(
                              height: overlayHeight,
                              child: IgnorePointer(
                                child: Row(
                                  spacing: 0.0,
                                  children: _buildOverlayWidgets(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onTextChanged() {
    final text = _controller.text;
    final previus = _previusText;
    final base = _controller.selection.baseOffset;
    final extent = _controller.selection.extentOffset;
    final recognizedKeys = widget.recognizedKeys;

    _handleTextChange(text, previus, base);
    _handleAutocomplete(text, base, extent, recognizedKeys);

    setState(() {
      _baseOffset = base;
      _extentOffset = extent;
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showAutocomplete(true);
    } else {
      if (!_isSelecting) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isSelecting && mounted) {
            _hideAutocomplete();
          }
        });
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.space &&
        event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed) {
      _showAutocomplete(true);
      _scrollToCaret();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter && event is KeyDownEvent) {
      if (_autocompleteMenu != null &&
          _selectedIndex >= 0 &&
          _selectedIndex < _filteredSuggestions.length) {
        _selectSuggestion(_filteredSuggestions[_selectedIndex], false);
        return KeyEventResult.handled;
      } else if (widget.onSubmitted != null) {
        widget.onSubmitted!(_text, _parts);
        if (widget.keepFocusedOnSubmit) {
          _hideAutocomplete();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (_filteredSuggestions.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _filteredSuggestions.length;
        _updateAutocomplete(false);
      });
      _autocompleteMenu?.markNeedsBuild();
      _scrollToSelected();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = _selectedIndex <= 0
            ? _filteredSuggestions.length - 1
            : _selectedIndex - 1;
        _updateAutocomplete(false);
      });
      _autocompleteMenu?.markNeedsBuild();
      _scrollToSelected();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent) {
      if (_autocompleteMenu != null) {
        _hideAutocomplete();
        setState(() {
          _filteredSuggestions = [];
        });
        return KeyEventResult.handled;
      }
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  double _getPaddingHorizontal() {
    return _getCommonPadding();
  }

  double _getCommonPadding() {
    return (widget.style.field.isDense ? 8 : 12);
  }

  void _iterateWords(
    String text,
    List<FieldKey> recognizedKeys,
    String operator, {
    void Function(int wordStartIndex, int wordEndIndex)? onEmptyWord,
    void Function(
      String word,
      int wordStartIndex,
      int wordEndIndex,
      _KeyMatch? match,
    )?
    onOperatorWord,
    void Function(String word, int wordStartIndex, int wordEndIndex)?
    onPartialWord,
  }) {
    final words = text.split(' ');

    int currentIndex = 0;
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final wordLength = word.length + (word.isEmpty ? 1 : 0);
      final increaseBySpace = (word.isEmpty ? 0 : 1);

      final wordStartIndex = currentIndex;
      final wordEndIndex = wordStartIndex + wordLength;

      if (word.isEmpty && onEmptyWord != null) {
        onEmptyWord(wordStartIndex, wordEndIndex);
      } else if (word.contains(operator) && onOperatorWord != null) {
        final match = _splitByOperator(
          word,
          wordStartIndex,
          wordEndIndex,
          operator,
          recognizedKeys,
        );
        onOperatorWord(word, wordStartIndex, wordEndIndex, match);
      } else if (onPartialWord != null) {
        onPartialWord(word, wordStartIndex, wordEndIndex);
      }

      currentIndex = currentIndex + wordLength + increaseBySpace;
    }
  }

  _WordIndex _getCaretWord(
    String text,
    int base,
    int extent,
    List<FieldKey> recognizedKeys,
  ) {
    if (base != extent) {
      return _WordIndex(
        type: _WordType.unknown,
        word: '',
        startIndex: -1,
        endIndex: -1,
      );
    }

    if (text.isEmpty) {
      return _WordIndex(
        type: _WordType.blank,
        word: '',
        startIndex: 0,
        endIndex: 0,
      );
    }

    final caret = base;
    _WordIndex? result;

    _iterateWords(
      text,
      recognizedKeys,
      "=",
      onEmptyWord: (wordStartIndex, wordEndIndex) {
        if (result == null &&
            caret >= wordStartIndex &&
            caret <= wordEndIndex) {
          result = _WordIndex(
            type: _WordType.blank,
            word: '',
            startIndex: wordStartIndex,
            endIndex: wordEndIndex,
          );
        }
      },
      onOperatorWord: (word, wordStartIndex, wordEndIndex, match) {
        if (result == null && caret == wordEndIndex && match != null) {
          final startIndex = wordStartIndex + match.valueStart;
          final endIndex = startIndex + (match.value?.length ?? 0);
          result = _WordIndex(
            type: _WordType.valueOfKey,
            word: match.value ?? "",
            startIndex: startIndex,
            endIndex: endIndex,
            key: match,
          );
        }
      },
      onPartialWord: (word, wordStartIndex, wordEndIndex) {
        if (result == null && caret == wordEndIndex) {
          result = _WordIndex(
            type: _WordType.partialWord,
            word: word,
            startIndex: wordStartIndex,
            endIndex: wordEndIndex,
          );
        }
      },
    );

    return result ??
        _WordIndex(
          type: _WordType.unknown,
          word: '',
          startIndex: -1,
          endIndex: -1,
        );
  }

  List<_KeyMatch> _findKeyMatches(String text, List<FieldKey> recognizedKeys) {
    if (text.isEmpty) return [];

    final matches = <_KeyMatch>[];
    List<FieldPart> parts = [];
    _text = "";

    _iterateWords(
      text,
      recognizedKeys,
      "=",
      onOperatorWord: (word, wordStartIndex, wordEndIndex, match) {
        if (match != null) {
          matches.add(match);

          parts.add(
            FieldPart(
              type: SegmentType.key,
              text: word,
              key: KeyPart(
                key: match.key.key,
                operator: match.operator,
                value: match.value,
              ),
            ),
          );
          if (widget.behavior.excludeTagsFromSubmitQuery == false) {
            _text += "$word ";
          }
        } else {
          _text += "$word ";
          if (widget.behavior.excludeQueryFromSubmitTags == false) {
            parts.add(FieldPart(type: SegmentType.text, text: word));
          }
        }
      },
      onPartialWord: (word, wordStartIndex, wordEndIndex) {
        _text += "$word ";
        if (widget.behavior.excludeQueryFromSubmitTags == false) {
          parts.add(FieldPart(type: SegmentType.text, text: word));
        }
      },
    );
    _text = _text.trim();
    _parts = parts;

    return matches;
  }

  _KeyMatch? _splitByOperator(
    String word,
    int wordStartIndex,
    int wordEndIndex,
    String operator,
    List<FieldKey> recognizedKeys,
  ) {
    final firstEqualIndex = word.indexOf(operator);
    final valueIndex = firstEqualIndex + 1;

    final key = word.substring(0, firstEqualIndex);
    final value = word.substring(valueIndex);

    final fieldKey = recognizedKeys
        .where((k) => k.key.toLowerCase() == key.toLowerCase())
        .firstOrNull;
    if (fieldKey == null) {
      return null;
    }

    final keyMatch = _KeyMatch(
      start: wordStartIndex,
      end: wordEndIndex,
      key: fieldKey,
      operator: operator,
      value: value,
      valueStart: valueIndex,
    );
    return keyMatch;
  }

  void _handleTextChange(String text, String previus, int base) {
    if (previus == text && text.isNotEmpty) {
      return;
    }
    _previusText = text;

    _text = text;
    _parts = [FieldPart(type: SegmentType.text, text: text)];
    _parseText(text);

    Future.delayed(Duration.zero, () {
      if (_controller.text.length >= base) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: base),
        );
      }
    });
  }

  void _parseText(String text) {
    final matches = _findKeyMatches(text, widget.recognizedKeys);

    if (matches.isEmpty) {
      setState(() {
        _segments = [_TextSegment(text)];
      });
      return;
    }

    List<_FieldSegment> newSegments = [];
    int lastEnd = 0;

    for (var match in matches) {
      if (match.start > lastEnd) {
        final beforeText = text.substring(lastEnd, match.start);
        if (beforeText.isNotEmpty) {
          newSegments.add(_TextSegment(beforeText));
        }
      }

      newSegments.add(_ChipSegment(key: match));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final afterText = text.substring(lastEnd);
      newSegments.add(_TextSegment(afterText));
    }

    if (newSegments.isEmpty ||
        newSegments.last is! _TextSegment ||
        (newSegments.last as _TextSegment).text.isNotEmpty) {
      newSegments.add(_TextSegment(''));
    }

    setState(() {
      _segments = newSegments;
    });
  }

  void _handleAutocomplete(
    String text,
    int base,
    int extent,
    List<FieldKey> recognizedKeys,
  ) {
    if (_isSelecting) {
      return;
    }

    final caretWord = _getCaretWord(text, base, extent, recognizedKeys);
    if (caretWord.type == _WordType.unknown) {
      _hideAutocomplete();
      return;
    }

    _updateSuggestions(caretWord, recognizedKeys);
  }

  void _updateSuggestions(_WordIndex caretWord, List<FieldKey> recognizedKeys) {
    final word = caretWord.word;
    final removeExactMatch = caretWord.type == _WordType.valueOfKey;

    final suggestions = _getSuggestions(recognizedKeys, caretWord);
    final filtered = _getFilteredSuggestions(
      word,
      suggestions,
      removeExactMatch,
    );

    setState(() {
      _filteredSuggestions = filtered;
      _selectedIndex = -1;
    });

    _updateAutocomplete(true);
  }

  List<_Suggestion> _getFilteredSuggestions(
    String word,
    List<_Suggestion> suggestions,
    bool removeExactMatch,
  ) {
    if (word.isEmpty) {
      return suggestions;
    }

    return suggestions
        .where(
          (s) =>
              s.word.toLowerCase().startsWith(word.toLowerCase()) &&
              (removeExactMatch
                  ? s.word.toLowerCase() != word.toLowerCase()
                  : true),
        )
        .toList();
  }

  List<_Suggestion> _getSuggestions(
    List<FieldKey> recognizedKeys,
    _WordIndex caretWord,
  ) {
    if (caretWord.type == _WordType.blank) {
      return _getKeySuggestions(recognizedKeys, caretWord);
    }

    if (caretWord.type == _WordType.partialWord) {
      return _getKeySuggestions(recognizedKeys, caretWord);
    }

    if (caretWord.type == _WordType.valueOfKey) {
      return _getKeyValueSuggestions(caretWord.key, caretWord);
    }

    return [];
  }

  List<_Suggestion> _getKeySuggestions(
    List<FieldKey> recognizedKeys,
    _WordIndex caretWord,
  ) {
    final keys = widget.behavior.allowDuplicatedKeys
        ? recognizedKeys
        : recognizedKeys.where(
            (k) => !_parts.any(
              (p) => p.type == SegmentType.key && p.key?.key == k.key,
            ),
          );
    return keys
        .map((k) => _Suggestion(word: k.key, wordOrigin: caretWord))
        .toList();
  }

  List<_Suggestion> _getKeyValueSuggestions(
    _KeyMatch? match,
    _WordIndex caretWord,
  ) {
    if (match == null) {
      return [];
    }

    return (match.key.suggestions ?? [])
        .map((k) => _Suggestion(word: k, wordOrigin: caretWord))
        .toList();
  }

  void _updateAutocomplete(bool isNew) {
    if (_focusNode.hasFocus) {
      if (_filteredSuggestions.isEmpty) {
        _hideAutocomplete();
      } else {
        _showAutocomplete(isNew);
      }
    }
  }

  void _hideAutocomplete() {
    _autocompleteMenu?.remove();
    _autocompleteMenu = null;
  }

  void _showAutocomplete(bool isNew) {
    if (_filteredSuggestions.isEmpty) return;

    if (isNew) {
      if (_autocompleteScrollController.hasClients) {
        _autocompleteScrollController.jumpTo(0);
      }
    }

    if (_autocompleteMenu != null) {
      _autocompleteMenu!.markNeedsBuild();
      return;
    }

    if (isNew) {
      _selectedIndex = -1;
    }

    _autocompleteMenu = _createAutocompleteMenu();
    Overlay.of(context).insert(_autocompleteMenu!);
  }

  void _calculateNewText(
    String text,
    _Suggestion suggestion,
    void Function(String newText, int newCursorPosition) onFinish,
  ) {
    final finalIndex = text.length;
    final previousType = suggestion.wordOrigin.type;
    final suggestionText = suggestion.word;

    var startIndex = suggestion.wordOrigin.startIndex;
    var endIndex = switch (previousType) {
      _WordType.blank => startIndex,
      _WordType.unknown => 0,
      _WordType.partialWord => suggestion.wordOrigin.endIndex,
      _WordType.valueOfKey => suggestion.wordOrigin.endIndex,
    };

    var endChar = switch (previousType) {
      _WordType.blank => "=",
      _WordType.unknown => "",
      _WordType.partialWord => "=",
      _WordType.valueOfKey => (startIndex == finalIndex ? " " : ""),
    };

    final beforeText = startIndex >= 0 ? text.substring(0, startIndex) : text;
    final afterText = endIndex >= 0
        ? text.substring(endIndex, finalIndex)
        : text;

    final finalText = "$beforeText$suggestionText$endChar$afterText";
    final newCursorPosition =
        startIndex + suggestion.word.length + endChar.length;
    onFinish(finalText, newCursorPosition);
  }

  void _selectSuggestion(_Suggestion suggestion, bool isMouse) {
    _isSelecting = true;

    final text = _controller.text;
    _calculateNewText(text, suggestion, (newText, newCursorPosition) {
      _isSelecting = false;
      _filteredSuggestions = [];
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newCursorPosition),
        ),
      );
      Future.delayed(const Duration(milliseconds: 10), () {
        _scrollToCaret();
      });
    });
  }

  void _scrollToCaret() {
    final caretX = _getCaretPositionX() + (_getPaddingHorizontal() * 2);
    if (_textScrollController.position.maxScrollExtent > 0 &&
        caretX >
            _textScrollController.offset +
                _textScrollController.position.viewportDimension) {
      double newPosition =
          caretX - _textScrollController.position.viewportDimension;

      if (_textScrollController.position.maxScrollExtent > newPosition) {
        if (_textScrollController.position.maxScrollExtent - newPosition < 3) {
          newPosition = _textScrollController.position.maxScrollExtent;
        }
      }

      _textScrollController.jumpTo(newPosition);
    }
  }

  TextStyle _getTextStyle({Color? color}) {
    return widget.style.text.baseTextStyle.copyWith(
      color: color,
      fontSize: widget.style.text.baseTextStyle.fontSize ?? _defaultFontSize,
      height: 1.2,
      letterSpacing: _letterSpacing,
    );
  }

  TextStyle _getTextTemplate() {
    return widget.style.text.baseTextStyle.copyWith(
      fontSize: widget.style.text.baseTextStyle.fontSize ?? _defaultFontSize,
      height: 1.4,
      letterSpacing: _letterSpacing,
    );
  }

  Widget _buildChip(int index, _ChipSegment chip) {
    final color = chip.key.key.color ?? widget.style.tag.defaultColor;

    int selStart = _baseOffset < _extentOffset ? _baseOffset : _extentOffset;
    int selEnd = _baseOffset < _extentOffset ? _extentOffset : _baseOffset;
    final careted = selStart <= chip.key.end && selEnd > chip.key.start;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: widget.style.tag.padding.top * -1,
          bottom: widget.style.tag.padding.bottom * -1,
          left: widget.style.tag.padding.left * -1,
          right: widget.style.tag.padding.right * -1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withAlpha(
                careted
                    ? widget.style.tag.focusedOpacity
                    : widget.style.tag.opacity,
              ),
              borderRadius: BorderRadius.circular(
                widget.style.tag.borderRadius,
              ),
              border: widget.style.tag.showBorder
                  ? Border.all(
                      color: color,
                      width: careted
                          ? widget.style.tag.focusedBorderWidth
                          : widget.style.tag.borderWidth,
                    )
                  : null,
            ),
          ),
        ),
        Row(
          children: [
            Text(
              chip.key.key.key,
              style: _getTextStyle(
                color: widget.style.tag.useColorForKey
                    ? color
                    : widget.style.text.textColor,
              ),
            ),
            Text(
              chip.key.operator,
              style: _getTextStyle(
                color: widget.style.tag.useColorForOperator
                    ? color
                    : widget.style.text.textColor,
              ),
            ),
            Text(
              chip.key.value ?? '',
              style: _getTextStyle(
                color: widget.style.tag.useColorForValue
                    ? color
                    : widget.style.text.textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextDisplay(int index, _TextSegment segment) {
    return Text(
      segment.text.isEmpty && index == 0 ? '' : segment.text,
      style: _getTextStyle(color: widget.style.text.textColor),
    );
  }

  double _getCaretPositionX() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _controller.text.substring(0, _controller.selection.baseOffset),
        style: _getTextTemplate(),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width;
  }

  double _getAutocompletePositionX() {
    double scrollOffset = _textScrollController.offset;
    final caretX = _getCaretPositionX();
    final autocompleteX = (caretX + _getPaddingHorizontal()) - scrollOffset;
    return autocompleteX;
  }

  OverlayEntry _createAutocompleteMenu() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        double caretX = _getAutocompletePositionX();
        final double width = widget.style.autocomplete.width;
        final double availableWidth = size.width - caretX;
        if (availableWidth < width) {
          caretX = size.width - width;
        }
        if (caretX < 0) {
          caretX = 0;
        }

        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(caretX, size.height + 2),
            child: Material(
              elevation: 2,
              borderOnForeground: true,
              surfaceTintColor: Colors.blue,
              borderRadius: widget.style.field.borderRadius,
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: widget.style.autocomplete.maxHeight,
                ),
                child: ListView.builder(
                  controller: _autocompleteScrollController,
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedIndex;
                    final suggestion = _filteredSuggestions[index];
                    final backColor = Colors.white;
                    final backFocusedColor = Colors.grey;

                    return MouseRegion(
                      onHover: (_) {
                        setState(() {
                          _selectedIndex = index;
                        });
                        _autocompleteMenu?.markNeedsBuild();
                      },
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          _selectSuggestion(suggestion, true);
                        },
                        child: Container(
                          height: widget.style.autocomplete.itemHeight,
                          color: isSelected
                              ? backFocusedColor.withAlpha(200)
                              : backColor.withAlpha(100),
                          padding: widget.style.autocomplete.itemPadding,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              suggestion.word,
                              style: _getTextStyle(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _scrollToSelected() {
    if (_selectedIndex < 0 || _filteredSuggestions.isEmpty) return;
    if (!_autocompleteScrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autocompleteScrollController.hasClients) return;

      final double targetPosition =
          _selectedIndex * widget.style.autocomplete.itemHeight;
      final double currentScroll =
          _autocompleteScrollController.position.pixels;
      final double viewportHeight =
          _autocompleteScrollController.position.viewportDimension;

      if (targetPosition < currentScroll) {
        _autocompleteScrollController.jumpTo(targetPosition);
      } else if (targetPosition + widget.style.autocomplete.itemHeight >
          currentScroll + viewportHeight) {
        _autocompleteScrollController.jumpTo(
          targetPosition -
              viewportHeight +
              widget.style.autocomplete.itemHeight,
        );
      }
    });
  }

  List<Widget> _buildOverlayWidgets() {
    List<Widget> widgets = [];

    for (int i = 0; i < _segments.length; i++) {
      if (_segments[i] is _ChipSegment) {
        widgets.add(_buildChip(i, _segments[i] as _ChipSegment));
      } else {
        final textSegment = _segments[i] as _TextSegment;
        if (textSegment.text.isNotEmpty || _segments.length == 1) {
          widgets.add(_buildTextDisplay(i, textSegment));
        }
      }
    }

    return widgets;
  }
}

class _KeyMatch {
  final int start;
  final int end;
  final FieldKey key;
  final String operator;
  final int valueStart;
  final String? value;

  String get text {
    return "${key.key}$operator$value";
  }

  _KeyMatch({
    required this.start,
    required this.end,
    required this.key,
    required this.operator,
    required this.valueStart,
    this.value,
  });
}

class _Suggestion {
  String word;
  _WordIndex wordOrigin;

  _Suggestion({required this.word, required this.wordOrigin});
}

class _WordIndex {
  _WordType type;
  String word;
  int startIndex;
  int endIndex;
  _KeyMatch? key;

  _WordIndex({
    required this.type,
    required this.word,
    required this.startIndex,
    required this.endIndex,
    this.key,
  });
}

enum _WordType {
  unknown, // No tag and no value of any tag
  blank, // Blank space, viable to add a tag
  partialWord,
  valueOfKey, // Value of a existing tag
}

abstract class _FieldSegment {
  int get length;
  String toText();
}

class _TextSegment extends _FieldSegment {
  String text;
  _TextSegment(this.text);

  @override
  int get length => text.length;

  @override
  String toText() => text;
}

class _ChipSegment extends _FieldSegment {
  _KeyMatch key;

  _ChipSegment({required this.key});

  @override
  int get length => toText().length;

  @override
  String toText() => '${key.key}${key.operator}${key.value}';
}
