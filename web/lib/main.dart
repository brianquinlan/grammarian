import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'grammarian_client.dart';
import 'models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grammarian',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ring of the Grammarian'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _client = GrammarianClient(client: http.Client());
  List<RingOfTheGrammarianSpell>? _spells;
  bool _isLoading = false;

  void _findSpells(String description) async {
    setState(() {
      _isLoading = true;
      _spells = null;
    });

    try {
      final spells = await _client.findSpells(description);
      setState(() {
        _spells = spells;
      });
    } catch (e) {
      print('Error finding spells: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error finding spells: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter spell description',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _findSpells,
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_spells != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _spells!.length,
                  itemBuilder: (context, index) {
                    return SpellCard(spell: _spells![index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SpellCard extends StatelessWidget {
  final RingOfTheGrammarianSpell spell;

  const SpellCard({super.key, required this.spell});

  @override
  Widget build(BuildContext context) {
    final grammarianSpell = spell.grammarianSpell;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grammarianSpell.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${grammarianSpell.level.jsonValue} ${grammarianSpell.school.jsonValue}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const Divider(),
            _buildStatGrid(context, grammarianSpell),
            const Divider(),
            const SizedBox(height: 8),
            SelectableText(
              grammarianSpell.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, Spell spell) {
    return Column(
      children: [
        _buildStatRow('Casting Time', spell.castingTime),
        _buildStatRow('Range', spell.range),
        _buildStatRow('Components', spell.components),
        _buildStatRow('Duration', spell.duration),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
