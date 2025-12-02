<p align="center">
  <img src="https://i.imgur.com/k2Pv5xI.png" width="587">
</p>

# TaggedField

A Flutter TextField with inline tag recognition, autocomplete suggestions, and real-time chip visualization. Ideal for building advanced search filters with `key=value` syntax.

## 🌐 Demo

Try the web demo: [tagged.datadev.app](https://tagged.datadev.app/)

## 📦 Install

```bash
flutter pub add tagged_field
```

## 🚀 Usage

```dart
import 'package:tagged_field/tagged_field.dart';

TaggedField(
    recognizedKeys: [
        FieldKey(key: 'status', color: Colors.blue, suggestions: ['open', 'closed', 'pending']),
        FieldKey(key: 'priority', color: Colors.red, suggestions: ['high', 'medium', 'low']),
        FieldKey(key: 'author', color: Colors.green),
    ],
    onSubmitted: (query, parts) {
        print('Query: $query');
    },
    behavior: TaggedFieldBehavior(
        allowDuplicatedKeys: false,
    ),
    style: TaggedFieldStyle(
        field: FieldStyle(
            borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        text: TextStyleConfig(
            baseTextStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
            ),
        ),
        tag: TagStyle(
            padding: EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 2.5,
            ),
        ),
    ),
)
```

## 🔑 Keys (tags)

Define which tags the field will recognize.  
A key is the identifier before the `=` operator (e.g., in `AppName=NationLogic`, the key is `AppName`).

```dart
recognizedKeys: [
    FieldKey(
        // Tag name (required)
        key: 'AppName',

        // Value suggestions for autocomplete (optional)
        // If not set, only the key will be suggested, not values
        suggestions: [
            'NationLogic',
            'SportService',
            'MilkRoad',
            // ...
        ],

        // Chip color (optional)
        color: Colors.blue,
    ),
]
```

## ⚡ onSubmitted

Callback triggered when the user submits the field (pressing Enter or completing input). Returns the query string and parsed parts.

```dart
// Input: "status=open priority=high flutter widgets"

onSubmitted: (query, parts) {
    print('Query: "$query"');
    
    for (final part in parts) {
        print('${part.key?.key}: "${part.key?.value}"');
    }
}

// Output:
// Query: "flutter widgets"
// status: "open"
// priority: "high"
```

## ⚙️ Custom behavior

Controls how the field processes and returns data: duplicate keys handling and submit output separation.

```dart
behavior: TaggedFieldBehavior(
    allowDuplicatedKeys: false,       // If allow same key multiple times (e.g., tag1=a tag1=b)
    excludeTagsFromSubmitQuery: true, // If query string contains only free text
    excludeQueryFromSubmitTags: true, // If parts list contains only recognized tags
)
```

## 🎨 Custom style

Full visual customization organized in four sub-styles:

```dart
style: TaggedFieldStyle(
    field: FieldStyle(...),
    text: TextStyleConfig(...),
    tag: TagStyle(...),
    autocomplete: AutocompleteStyle(...),
)
```

### FieldStyle

Container appearance: borders, border radius, background color, and compact mode.

```dart
field: FieldStyle(
    border: Border.fromBorderSide(BorderSide(color: Colors.grey)),
    focusedBorder: Border.fromBorderSide(BorderSide(color: Colors.blue)),
    borderRadius: BorderRadius.circular(8),
    backgroundColor: Colors.white,
    isDense: false,
)
```

### TextStyleConfig

Text and cursor appearance.

```dart
text: TextStyleConfig(
    cursorColor: Colors.blue,
    cursorWidth: 1.0,
    baseTextStyle: TextStyle(fontSize: 14),
    textColor: Colors.black,
)
```

### TagStyle

Chip rendering: background opacity, border, radius, padding, and color inheritance.

```dart
tag: TagStyle(
    defaultColor: Colors.grey,
    opacity: 60,
    focusedOpacity: 30,
    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 0.5),
    showBorder: true,
    borderWidth: 0.3,
    focusedBorderWidth: 0.5,
    borderRadius: 4.0,
    useColorForKey: true,
    useColorForOperator: true,
    useColorForValue: false,
)
```

### AutocompleteStyle

Dropdown dimensions and item styling.

```dart
autocomplete: AutocompleteStyle(
    width: 200,
    maxHeight: 250,
    itemHeight: 48,
    itemPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
)
```