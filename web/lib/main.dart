import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:grammarian_web/spell_card.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'grammarian_client.dart';
import 'models.dart';
import 'login_page.dart';
import 'firebase_options.dart';

// --- Theme Constants ---
class AppColors {
  static const primary = Color(0xFF7f13ec);
  static const backgroundDark = Color(0xFF131117);
  static const backgroundLight = Color(0xFFf7f6f8);
  static const surfaceDark = Color(0xFF1e1a24);
  static const surfaceCard = Color(0xFF251e30);
  static const surfaceBorder = Color(0xFF3b3047);
  static const textWhite = Colors.white;
  static const textGray = Color(0xFFab9db9);
  static const textLightGray = Color(0xFFe2e8f0);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      } catch (e) {
        print('Failed to use Firebase Auth Emulator: $e');
      }
    }
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grammarian Sage',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surfaceCard,
          onSurface: AppColors.textWhite,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const MainLayout();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _client = GrammarianClient(client: http.Client());
  List<ConversationSummary> _conversations = [];
  Conversation? _currentConversation;
  String? _currentConversationId;
  bool _isLoading = false;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        _client.authToken = token;
        await _loadConversations();
      } catch (e) {
        if (mounted) _showError('Error initializing session: $e');
      }
    }
  }

  Future<void> _loadConversations() async {
    try {
      final response = await _client.getConversations();
      setState(() {
        _conversations = response.conversations;
        _conversations.sort((a, b) => b.createdOn.compareTo(a.createdOn));
      });
    } catch (e) {
      if (mounted) _showError('Error loading history: $e');
    }
  }

  Future<void> _selectConversation(String conversationId) async {
    setState(() {
      _isLoading = true;
      _currentConversationId = conversationId;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) _client.authToken = await user.getIdToken();
      final conversation = await _client.getConversation(conversationId);
      setState(() => _currentConversation = conversation);
    } catch (e) {
      if (mounted) _showError('Error loading conversation: $e');
    } finally {
      setState(() => _isLoading = false);
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
    if (text.trim().isEmpty) return;

    // 1. Check if this is a new conversation request
    final isNewConversation = _currentConversationId == null;
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _isLoading = true;

      if (isNewConversation) {
        // 2. Optimistic UI Update: Create placeholder conversation
        final tempSummary = ConversationSummary(
          conversationId: tempId,
          createdOn: DateTime.now(),
          name: '...',
        );
        _conversations.insert(0, tempSummary);

        _currentConversationId = tempId;
        _currentConversation = Conversation(
          conversationId: tempId,
          createdOn: DateTime.now(),
          name: '...',
          model: 'pending',
          dialog: [UserPrompt(text: text)],
        );
      }
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) _client.authToken = await user.getIdToken();

      // 3. Make API Call (pass null if it's a new conversation, despite local temp ID)
      final conversationIdToSend = isNewConversation
          ? null
          : _currentConversationId;
      final response = await _client.prompt(
        text,
        conversationId: conversationIdToSend,
      );

      if (isNewConversation) {
        // 4. Handle New Conversation Response: Fetch full details to get the generated name
        final fullConversation = await _client.getConversation(
          response.conversationId,
        );

        setState(() {
          // Remove the temporary placeholder
          _conversations.removeWhere((c) => c.conversationId == tempId);

          // Create summary with the real name and ID
          final newSummary = ConversationSummary(
            conversationId: fullConversation.conversationId,
            createdOn: fullConversation.createdOn,
            name: fullConversation.name,
          );

          // Insert at top and update current view
          _conversations.insert(0, newSummary);
          _currentConversationId = fullConversation.conversationId;
          _currentConversation = fullConversation;
        });
      } else {
        // 5. Handle Existing Conversation Response: Refresh view
        if (_currentConversationId != null) {
          await _selectConversation(_currentConversationId!);
        }
      }

      _promptController.clear();
    } catch (e) {
      if (mounted) {
        _showError('Error finding spells: $e');
        // Revert optimistic updates if failed
        if (isNewConversation) {
          setState(() {
            _conversations.removeWhere((c) => c.conversationId == tempId);
            _currentConversationId = null;
            _currentConversation = null;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopHeader(),
          Expanded(
            child: Row(
              children: [
                // Sidebar (Hidden on small screens, strictly following mock design)
                if (MediaQuery.of(context).size.width > 768)
                  SizedBox(
                    width: 280,
                    child: Sidebar(
                      conversations: _conversations,
                      currentId: _currentConversationId,
                      onSelect: _selectConversation,
                      onNew: _createNewConversation,
                    ),
                  ),
                // Main Content
                Expanded(
                  child: Container(
                    color: AppColors.backgroundDark,
                    child: Column(
                      children: [
                        Expanded(
                          child: ChatArea(
                            conversation: _currentConversation,
                            isLoading: _isLoading,
                          ),
                        ),
                        InputArea(
                          controller: _promptController,
                          isLoading: _isLoading,
                          onSubmit: _submitPrompt,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Components ---

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.shield,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Grammarian Sage',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
          if (user != null)
            PopupMenuButton(
              offset: const Offset(0, 48),
              color: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.surfaceBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceBorder,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.textGray,
                      )
                    : null,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => FirebaseAuth.instance.signOut(),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: AppColors.textGray),
                      SizedBox(width: 8),
                      Text(
                        'Log out',
                        style: TextStyle(color: AppColors.textGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  final List<ConversationSummary> conversations;
  final String? currentId;
  final Function(String) onSelect;
  final VoidCallback onNew;

  const Sidebar({
    super.key,
    required this.conversations,
    required this.currentId,
    required this.onSelect,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    // Group conversations (simplification)
    final now = DateTime.now();
    final today = conversations
        .where(
          (c) =>
              c.createdOn.year == now.year &&
              c.createdOn.month == now.month &&
              c.createdOn.day == now.day,
        )
        .toList();
    final others = conversations.where((c) => !today.contains(c)).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0e0c11),
        border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: onNew,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.surfaceBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'New Scenario',
                      style: TextStyle(
                        color: AppColors.textLightGray,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                if (today.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        color: Color(0xFF554b60),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...today.map((c) => _buildNavItem(c, context)),
                ],
                if (others.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'HISTORY',
                      style: TextStyle(
                        color: Color(0xFF554b60),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...others.map((c) => _buildNavItem(c, context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(ConversationSummary summary, BuildContext context) {
    final isSelected = summary.conversationId == currentId;
    return InkWell(
      onTap: () => onSelect(summary.conversationId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.surfaceBorder.withOpacity(0.4),
                border: Border.all(
                  color: AppColors.surfaceBorder.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF554b60),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                summary.name.isEmpty ? 'Untitled' : summary.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFab9db9),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatArea extends StatelessWidget {
  final Conversation? conversation;
  final bool isLoading;

  const ChatArea({
    super.key,
    required this.conversation,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            const Text(
              'Greetings, adventurer.',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'I am your arcane assistant. Tell me about your character,\nor ask for a specific spell to begin your journey.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, height: 1.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      itemCount: conversation!.dialog.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= conversation!.dialog.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Row(
              children: [
                SageAvatar(),
                SizedBox(width: 16),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          );
        }

        final item = conversation!.dialog[index];
        if (item is UserPrompt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border.all(color: AppColors.surfaceBorder),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(2),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        color: AppColors.textLightGray,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (item is AppResponse) {
          return AssistantMessage(response: item);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class AssistantMessage extends StatefulWidget {
  final AppResponse response;

  const AssistantMessage({super.key, required this.response});

  @override
  State<AssistantMessage> createState() => _AssistantMessageState();
}

class _AssistantMessageState extends State<AssistantMessage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SageAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The Sage',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.response.spells.isNotEmpty) ...[
                  const Text(
                    'Here are some options for your request:',
                    style: TextStyle(
                      color: AppColors.textLightGray,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 500,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: widget.response.spells.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, i) => SizedBox(
                          width: 300,
                          child: SpellCard(spell: widget.response.spells[i]),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SageAvatar extends StatelessWidget {
  const SageAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
    );
  }
}

class InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String) onSubmit;

  const InputArea({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.backgroundDark, Colors.transparent],
          stops: [0.5, 1.0],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.surfaceBorder),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  if (!isLoading) onSubmit(controller.text);
                },
              },
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText:
                      'Ask for a spell, describe a scenario, or check rules...',
                  hintStyle: TextStyle(color: AppColors.textGray),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onSubmitted: onSubmit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
