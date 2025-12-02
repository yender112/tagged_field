part of '../main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TaggedField Demo",
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF027eb6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF01547a),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: DemoPage(isDark: _isDark, onToggleTheme: _toggleTheme),
    );
  }
}

class DemoPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const DemoPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Image(
                    image: AssetImage('assets/img/tagged_field_title.png'),
                  ),
                ),
                const SizedBox(height: 48),

                // ═══════════════════════════════════════════════════════════
                // BASIC
                // ═══════════════════════════════════════════════════════════
                _card(
                  title: 'Basic Usage',
                  subtitle: 'Default configuration',
                  icon: Icons.filter_list,
                  color: Colors.blue,
                  child: basicUsageExample(),
                ),

                const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════════════
                // MONOSPACE (Roboto Mono)
                // ═══════════════════════════════════════════════════════════
                _card(
                  title: 'Monospace Font',
                  subtitle: 'Using Roboto Mono',
                  icon: Icons.terminal,
                  color: Colors.deepPurple,
                  child: monospaceEmaple(),
                ),

                const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════════════
                // SEARCH BAR
                // ═══════════════════════════════════════════════════════════
                _card(
                  title: 'Search Bar',
                  subtitle: 'Full Search Example',
                  icon: Icons.search,
                  color: Colors.red,
                  child: searchBarExample(),
                ),

                const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════════════
                // COMPACT
                // ═══════════════════════════════════════════════════════════
                _card(
                  title: 'Compact Mode',
                  subtitle: 'isDense enabled',
                  icon: Icons.compress,
                  color: Colors.teal,
                  child: compactExample(),
                ),

                SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(60),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}
