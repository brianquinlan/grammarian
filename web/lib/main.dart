import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<ConversationSummary> _conversations = [];
  Conversation? _currentConversation;
  String? _currentConversationId;
  bool _isLoading = false;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final response = await _client.getConversations();
      setState(() {
        _conversations = response.conversations;
        // Sort by createdOn descending
        _conversations.sort((a, b) => b.createdOn.compareTo(a.createdOn));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    }
  }

  Future<void> _selectConversation(String conversationId) async {
    setState(() {
      _isLoading = true;
      _currentConversationId = conversationId;
    });

    try {
      final conversation = await _client.getConversation(conversationId);
      setState(() {
        _currentConversation = conversation;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createNewConversation() {
    setState(() {
      _currentConversationId = null;
      _currentConversation = null;
      _promptController.clear();
    });
  }

  Future<void> _submitPrompt(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _client.prompt(
        text,
        conversationId: _currentConversationId,
      );

      // If this was a new conversation, we need to refresh the list and set the ID
      if (_currentConversationId == null) {
        await _loadConversations();
        _currentConversationId = response.conversationId;
      }

      // Refresh the current conversation to get the full history including the new exchange
      if (_currentConversationId != null) {
        await _selectConversation(_currentConversationId!);
      }

      _promptController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finding spells: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 300,
            child: ConversationListPanel(
              conversations: _conversations,
              currentConversationId: _currentConversationId,
              onSelect: _selectConversation,
              onNew: _createNewConversation,
            ),
          ),
          const VerticalDivider(width: 1),
          // Main Content
          Expanded(
            child: ConversationDetailPanel(
              conversation: _currentConversation,
              isLoading: _isLoading,
              onSubmit: _submitPrompt,
              controller: _promptController,
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationListPanel extends StatelessWidget {
  final List<ConversationSummary> conversations;
  final String? currentConversationId;
  final Function(String) onSelect;
  final VoidCallback onNew;

  const ConversationListPanel({
    super.key,
    required this.conversations,
    required this.currentConversationId,
    required this.onSelect,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: const Text('New Conversation'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final summary = conversations[index];
              final isSelected =
                  summary.conversationId == currentConversationId;
              return ListTile(
                title: Text(
                  summary.name.isEmpty ? 'Untitled' : summary.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  summary.createdOn.toString().substring(
                    0,
                    16,
                  ), // Simple formatting
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                selected: isSelected,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                onTap: () => onSelect(summary.conversationId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ConversationDetailPanel extends StatelessWidget {
  final Conversation? conversation;
  final bool isLoading;
  final Function(String) onSubmit;
  final TextEditingController controller;

  const ConversationDetailPanel({
    super.key,
    required this.conversation,
    required this.isLoading,
    required this.onSubmit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: conversation == null
              ? const Center(
                  child: Text(
                    'Select a conversation or start a new one.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversation!.dialog.length,
                  itemBuilder: (context, index) {
                    final item = conversation!.dialog[index];
                    if (item is UserPrompt) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Text(
                            item.text,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      );
                    } else if (item is AppResponse) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: item.spells
                            .map((spell) => SpellCard(spell: spell))
                            .toList(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ),
        if (isLoading) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter spell description',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: onSubmit,
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: isLoading ? null : () => onSubmit(controller.text),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
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
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  grammarianSpell.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy Markdown',
                  onPressed: () {
                    final markdown =
                        '''
### ${grammarianSpell.name}
*${grammarianSpell.level.jsonValue} ${grammarianSpell.school.jsonValue}*

**Casting Time:** ${grammarianSpell.castingTime}
**Range:** ${grammarianSpell.range}
**Components:** ${grammarianSpell.components}
**Duration:** ${grammarianSpell.duration}
**Original Spell:** ${spell.originalSpellName}

${grammarianSpell.description}
''';
                    Clipboard.setData(ClipboardData(text: markdown));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${grammarianSpell.level.jsonValue} ${grammarianSpell.school.jsonValue}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const Divider(),
            _buildStatGrid(context, spell),
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

  Widget _buildStatGrid(BuildContext context, RingOfTheGrammarianSpell spell) {
    final gSpell = spell.grammarianSpell;
    return Column(
      children: [
        _buildStatRow('Casting Time', gSpell.castingTime),
        _buildStatRow('Range', gSpell.range),
        _buildStatRow('Components', gSpell.components),
        _buildStatRow('Duration', gSpell.duration),
        _buildStatRow('Original Spell', spell.originalSpellName),
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
