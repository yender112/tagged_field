import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/behavior.dart';
import 'models/models.dart';
import 'models/style.dart';

import 'utils/key_model.dart';
import 'utils/segments_types.dart';

class TaggedField extends StatefulWidget {
  final List<FieldKey> recognizedKeys;
  final Function(String query, List<FieldPart> parts)? onSubmitted;
  final TaggedFieldStyle style;
  final TaggedFieldBehavior behavior;
  final FocusNode? focusNode;
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
  State<TaggedField> createState() => TaggedFieldState();
}

class TaggedFieldState extends State<TaggedField> {
  late FocusNode _focusNode;
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final ScrollController _textScrollController = ScrollController();
  final ScrollController _autocompleteScrollController = ScrollController();
  OverlayEntry? _autocompleteMenu;

  List<FieldSegment> _segments = [TextSegment('')];
  List<FieldPart> _parts = [];
  String _text = "";

  static const double _letterSpacing = 0.0;
  static const double _standardHeigth = 48;
  static const double _denseHeigth = 40;
  static const double _defaultFontSize = 14;

  List<Suggestion> _filteredSuggestions = [];
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
    hideAutocomplete();
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
                    hideAutocomplete();
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
                              style: getTextStyle(color: Colors.transparent),
                              cursorColor: widget.style.text.cursorColor,
                              cursorWidth: widget.style.text.cursorWidth,
                              textAlignVertical: isDense
                                  ? TextAlignVertical.center
                                  : TextAlignVertical.top,
                              onSubmitted: (value) {
                                widget.onSubmitted!(_text, _parts);
                                hideAutocomplete();
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
                                  children: buildOverlayWidgets(),
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

    handleTextChange(text, previus, base);
    handleAutocomplete(text, base, extent, recognizedKeys);

    setState(() {
      _baseOffset = base;
      _extentOffset = extent;
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      showAutocomplete(true);
    } else {
      if (!_isSelecting) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isSelecting && mounted) {
            hideAutocomplete();
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
      showAutocomplete(true);
      scrollToCaret();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter && event is KeyDownEvent) {
      if (_autocompleteMenu != null &&
          _selectedIndex >= 0 &&
          _selectedIndex < _filteredSuggestions.length) {
        selectSuggestion(_filteredSuggestions[_selectedIndex], false);
        return KeyEventResult.handled;
      } else if (widget.onSubmitted != null) {
        widget.onSubmitted!(_text, _parts);
        if (widget.keepFocusedOnSubmit) {
          hideAutocomplete();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (_filteredSuggestions.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _filteredSuggestions.length;
        updateAutocomplete(false);
      });
      _autocompleteMenu?.markNeedsBuild();
      scrollToSelected();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = _selectedIndex <= 0
            ? _filteredSuggestions.length - 1
            : _selectedIndex - 1;
        updateAutocomplete(false);
      });
      _autocompleteMenu?.markNeedsBuild();
      scrollToSelected();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent) {
      if (_autocompleteMenu != null) {
        hideAutocomplete();
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

  double getPaddingHorizontal() {
    return getCommonPadding();
  }

  double getPaddingVertical(bool isOverlay) {
    if (isOverlay && widget.style.field.isDense) {
      return _denseHeigth / 4;
    }
    return getCommonPadding();
  }

  double getCommonPadding() {
    return (widget.style.field.isDense ? 8 : 12);
  }

  void iterateWords(
    String text,
    List<FieldKey> recognizedKeys,
    String operator, {
    void Function(int wordStartIndex, int wordEndIndex)? onEmptyWord,
    void Function(
      String word,
      int wordStartIndex,
      int wordEndIndex,
      KeyMatch? match,
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
        final match = splitByOperator(
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

  WordIndex getCaretWord(
    String text,
    int base,
    int extent,
    List<FieldKey> recognizedKeys,
  ) {
    if (base != extent) {
      return WordIndex(
        type: WordType.unknown,
        word: '',
        startIndex: -1,
        endIndex: -1,
      );
    }

    if (text.isEmpty) {
      return WordIndex(
        type: WordType.blank,
        word: '',
        startIndex: 0,
        endIndex: 0,
      );
    }

    final caret = base;
    WordIndex? result;

    iterateWords(
      text,
      recognizedKeys,
      "=",
      onEmptyWord: (wordStartIndex, wordEndIndex) {
        if (result == null &&
            caret >= wordStartIndex &&
            caret <= wordEndIndex) {
          result = WordIndex(
            type: WordType.blank,
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
          result = WordIndex(
            type: WordType.valueOfKey,
            word: match.value ?? "",
            startIndex: startIndex,
            endIndex: endIndex,
            key: match,
          );
        }
      },
      onPartialWord: (word, wordStartIndex, wordEndIndex) {
        if (result == null && caret == wordEndIndex) {
          result = WordIndex(
            type: WordType.partialWord,
            word: word,
            startIndex: wordStartIndex,
            endIndex: wordEndIndex,
          );
        }
      },
    );

    return result ??
        WordIndex(
          type: WordType.unknown,
          word: '',
          startIndex: -1,
          endIndex: -1,
        );
  }

  List<KeyMatch> findKeyMatches(String text, List<FieldKey> recognizedKeys) {
    if (text.isEmpty) return [];

    final matches = <KeyMatch>[];
    List<FieldPart> parts = [];
    _text = "";

    iterateWords(
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

  KeyMatch? splitByOperator(
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

    final keyMatch = KeyMatch(
      start: wordStartIndex,
      end: wordEndIndex,
      key: fieldKey,
      operator: operator,
      value: value,
      valueStart: valueIndex,
    );
    return keyMatch;
  }

  void handleTextChange(String text, String previus, int base) {
    if (previus == text && text.isNotEmpty) {
      return;
    }
    _previusText = text;

    _text = text;
    _parts = [FieldPart(type: SegmentType.text, text: text)];
    parseText(text);

    Future.delayed(Duration.zero, () {
      if (_controller.text.length >= base) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: base),
        );
      }
    });
  }

  void parseText(String text) {
    final matches = findKeyMatches(text, widget.recognizedKeys);

    if (matches.isEmpty) {
      setState(() {
        _segments = [TextSegment(text)];
      });
      return;
    }

    List<FieldSegment> newSegments = [];
    int lastEnd = 0;

    for (var match in matches) {
      if (match.start > lastEnd) {
        final beforeText = text.substring(lastEnd, match.start);
        if (beforeText.isNotEmpty) {
          newSegments.add(TextSegment(beforeText));
        }
      }

      newSegments.add(ChipSegment(key: match));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final afterText = text.substring(lastEnd);
      newSegments.add(TextSegment(afterText));
    }

    if (newSegments.isEmpty ||
        newSegments.last is! TextSegment ||
        (newSegments.last as TextSegment).text.isNotEmpty) {
      newSegments.add(TextSegment(''));
    }

    setState(() {
      _segments = newSegments;
    });
  }

  void handleAutocomplete(
    String text,
    int base,
    int extent,
    List<FieldKey> recognizedKeys,
  ) {
    if (_isSelecting) {
      return;
    }

    final caretWord = getCaretWord(text, base, extent, recognizedKeys);
    if (caretWord.type == WordType.unknown) {
      hideAutocomplete();
      return;
    }

    updateSuggestions(caretWord, recognizedKeys);
  }

  void updateSuggestions(WordIndex caretWord, List<FieldKey> recognizedKeys) {
    final word = caretWord.word;
    final removeExactMatch = caretWord.type == WordType.valueOfKey;

    final suggestions = getSuggestions(recognizedKeys, caretWord);
    final filtered = getFilteredSuggestions(
      word,
      suggestions,
      removeExactMatch,
    );

    setState(() {
      _filteredSuggestions = filtered;
      _selectedIndex = -1;
    });

    updateAutocomplete(true);
  }

  List<Suggestion> getFilteredSuggestions(
    String word,
    List<Suggestion> suggestions,
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

  List<Suggestion> getSuggestions(
    List<FieldKey> recognizedKeys,
    WordIndex caretWord,
  ) {
    if (caretWord.type == WordType.blank) {
      return getKeySuggestions(recognizedKeys, caretWord);
    }

    if (caretWord.type == WordType.partialWord) {
      return getKeySuggestions(recognizedKeys, caretWord);
    }

    if (caretWord.type == WordType.valueOfKey) {
      return getKeyValueSuggestions(caretWord.key, caretWord);
    }

    return [];
  }

  List<Suggestion> getKeySuggestions(
    List<FieldKey> recognizedKeys,
    WordIndex caretWord,
  ) {
    final keys = widget.behavior.allowDuplicatedKeys
        ? recognizedKeys
        : recognizedKeys.where(
            (k) => !_parts.any(
              (p) => p.type == SegmentType.key && p.key?.key == k.key,
            ),
          );
    return keys
        .map((k) => Suggestion(word: k.key, wordOrigin: caretWord))
        .toList();
  }

  List<Suggestion> getKeyValueSuggestions(
    KeyMatch? match,
    WordIndex caretWord,
  ) {
    if (match == null) {
      return [];
    }

    return (match.key.suggestions ?? [])
        .map((k) => Suggestion(word: k, wordOrigin: caretWord))
        .toList();
  }

  void updateAutocomplete(bool isNew) {
    if (_focusNode.hasFocus) {
      if (_filteredSuggestions.isEmpty) {
        hideAutocomplete();
      } else {
        showAutocomplete(isNew);
      }
    }
  }

  void hideAutocomplete() {
    _autocompleteMenu?.remove();
    _autocompleteMenu = null;
  }

  void showAutocomplete(bool isNew) {
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

    _autocompleteMenu = createAutocompleteMenu();
    Overlay.of(context).insert(_autocompleteMenu!);
  }

  void calculateNewText(
    String text,
    Suggestion suggestion,
    void Function(String newText, int newCursorPosition) onFinish,
  ) {
    final finalIndex = text.length;
    final previousType = suggestion.wordOrigin.type;
    final suggestionText = suggestion.word;

    var startIndex = suggestion.wordOrigin.startIndex;
    var endIndex = switch (previousType) {
      WordType.blank => startIndex,
      WordType.unknown => 0,
      WordType.partialWord => suggestion.wordOrigin.endIndex,
      WordType.valueOfKey => suggestion.wordOrigin.endIndex,
    };

    var endChar = switch (previousType) {
      WordType.blank => "=",
      WordType.unknown => "",
      WordType.partialWord => "=",
      WordType.valueOfKey => (startIndex == finalIndex ? " " : ""),
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

  void selectSuggestion(Suggestion suggestion, bool isMouse) {
    _isSelecting = true;

    final text = _controller.text;
    calculateNewText(text, suggestion, (newText, newCursorPosition) {
      _isSelecting = false;
      _filteredSuggestions = [];
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newCursorPosition),
        ),
      );
      Future.delayed(const Duration(milliseconds: 10), () {
        scrollToCaret();
      });
    });
  }

  void scrollToCaret() {
    final caretX = getCaretPositionX() + (getPaddingHorizontal() * 2);
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

  TextStyle getTextStyle({Color? color}) {
    return widget.style.text.baseTextStyle.copyWith(
      color: color,
      fontSize: widget.style.text.baseTextStyle.fontSize ?? _defaultFontSize,
      height: 1.2,
      letterSpacing: _letterSpacing,
    );
  }

  TextStyle getTextTemplate() {
    return widget.style.text.baseTextStyle.copyWith(
      fontSize: widget.style.text.baseTextStyle.fontSize ?? _defaultFontSize,
      height: 1.4,
      letterSpacing: _letterSpacing,
    );
  }

  Widget buildChip(int index, ChipSegment chip) {
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
              style: getTextStyle(
                color: widget.style.tag.useColorForKey
                    ? color
                    : widget.style.text.textColor,
              ),
            ),
            Text(
              chip.key.operator,
              style: getTextStyle(
                color: widget.style.tag.useColorForOperator
                    ? color
                    : widget.style.text.textColor,
              ),
            ),
            Text(
              chip.key.value ?? '',
              style: getTextStyle(
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

  Widget buildTextDisplay(int index, TextSegment segment) {
    return Text(
      segment.text.isEmpty && index == 0 ? '' : segment.text,
      style: getTextStyle(color: widget.style.text.textColor),
    );
  }

  double getCaretPositionX() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _controller.text.substring(0, _controller.selection.baseOffset),
        style: getTextTemplate(),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width;
  }

  double getAutocompletePositionX() {
    double scrollOffset = _textScrollController.offset;
    final caretX = getCaretPositionX();
    final autocompleteX = (caretX + getPaddingHorizontal()) - scrollOffset;
    return autocompleteX;
  }

  OverlayEntry createAutocompleteMenu() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        double caretX = getAutocompletePositionX();
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
                          selectSuggestion(suggestion, true);
                        },
                        child: Container(
                          height: widget.style.autocomplete.itemHeight,
                          color: isSelected
                              ? backFocusedColor.withAlpha(200)
                              : backColor.withAlpha(100),
                          padding: widget.style.autocomplete.itemPadding,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(suggestion.word, style: getTextStyle()),
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

  void scrollToSelected() {
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

  List<Widget> buildOverlayWidgets() {
    List<Widget> widgets = [];

    for (int i = 0; i < _segments.length; i++) {
      if (_segments[i] is ChipSegment) {
        widgets.add(buildChip(i, _segments[i] as ChipSegment));
      } else {
        final textSegment = _segments[i] as TextSegment;
        if (textSegment.text.isNotEmpty || _segments.length == 1) {
          widgets.add(buildTextDisplay(i, textSegment));
        }
      }
    }

    return widgets;
  }
}
