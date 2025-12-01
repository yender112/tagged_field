import 'package:flutter/material.dart';
import 'package:tagged_field/tagged_field.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tagged Field Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  String _lastQuery = '';
  List<FieldPart> _lastParts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tagged Field Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaggedField(
              recognizedKeys: [
                FieldKey(
                  key: 'status',
                  color: Colors.blue,
                  suggestions: ['open', 'closed', 'pending', 'in-progress'],
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
                FieldKey(
                  key: 'type',
                  color: Colors.orange,
                  suggestions: ['bug', 'feature', 'task'],
                ),
              ],
              onSubmitted: (query, parts) {
                setState(() {
                  _lastQuery = query;
                  _lastParts = parts;
                });
              },
              behavior: const TaggedFieldBehavior(
                allowDuplicatedKeys: false,
                excludeTagsFromSubmitQuery: true,
                excludeQueryFromSubmitTags: true,
              ),
              style: TaggedFieldStyle(
                field: FieldStyle(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  focusedBorder: Border.all(color: Colors.blue, width: 2),
                ),
                text: const TextStyleConfig(
                  baseTextStyle: TextStyle(fontSize: 15),
                  cursorColor: Colors.blue,
                ),
                tag: const TagStyle(
                  borderRadius: 6,
                  opacity: 50,
                  focusedOpacity: 80,
                ),
                autocomplete: const AutocompleteStyle(
                  width: 220,
                  maxHeight: 200,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Query: "$_lastQuery"',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Recognized tags:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ..._lastParts.map(
              (part) => Text(
                '${part.key?.key}: "${part.key?.value}"',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
