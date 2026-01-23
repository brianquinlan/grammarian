import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:grammarian_web/assistant_message.dart';
import 'package:grammarian_web/chat_area.dart';
import 'package:grammarian_web/input_area.dart';
import 'package:grammarian_web/sidebar.dart';
import 'package:grammarian_web/spell_card.dart';
import 'package:grammarian_web/top_header.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'grammarian_client.dart';
import 'models.dart';
import 'login_page.dart';
import 'firebase_options.dart';
import 'package:uuid/uuid.dart';

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
  List<ModelInfo> _models = [];
  Conversation? _currentConversation;
  String? _currentConversationId;
  String? _selectedModel;
  final Set<String> _pendingRequests = {};
  final Map<String, Conversation> _pendingConversationState = {};
  bool _isFetching = false;
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        _client.authToken = token;
        await Future.wait([_loadConversations(), _loadModels()]);
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

  Future<void> _loadModels() async {
    try {
      final response = await _client.getModels();
      if (mounted) {
        setState(() {
          _models = response.models;
          if (_models.isNotEmpty) {
            _selectedModel = _models.first.model;
          }
        });
      }
    } catch (e) {
      if (mounted) _showError('Error loading models: $e');
    }
  }

  Future<void> _selectConversation(String conversationId) async {
    setState(() {
      _isFetching = true;
      _currentConversationId = conversationId;
    });

    if (_pendingConversationState.containsKey(conversationId)) {
      setState(() {
        _currentConversation = _pendingConversationState[conversationId];
        _isFetching = false;
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) _client.authToken = await user.getIdToken();
      final conversation = await _client.getConversation(conversationId);
      setState(() => _currentConversation = conversation);
    } catch (e) {
      if (mounted) _showError('Error loading conversation: $e');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _createNewConversation() {
    setState(() {
      _currentConversationId = null;
      _currentConversation = null;
      _currentConversationId = null;
      _currentConversation = null;
      _promptController.clear();
      // Reset model selection to default (first available)
      if (_models.isNotEmpty) {
        _selectedModel = _models.first.model;
      }
    });
  }

  Future<void> _submitPrompt(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Check if this is a new conversation request
    final isNewConversation = _currentConversationId == null;
    final tempId = _uuid.v4();
    final currentId = isNewConversation ? tempId : _currentConversationId!;

    setState(() {
      _pendingRequests.add(currentId);

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
      } else {
        // For existing conversation, optimistically add user prompt to UI immediately if needed,
        // but current implementation relies on server response.
        // Let's at least clear input so user knows it's sent.
        _promptController.clear();
      }
      _pendingConversationState[currentId] = _currentConversation!;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) _client.authToken = await user.getIdToken();

      // 3. Make API Call
      PromptResponse response;
      if (isNewConversation) {
        response = await _client.createConversation(
          tempId,
          text,
          _selectedModel ?? 'gemini-1.5-flash',
        );
      } else {
        response = await _client.updateConversation(currentId, text);
      }

      if (!mounted) return;

      if (isNewConversation) {
        // 4. Handle New Conversation Response: Fetch full details to get the generated name
        final fullConversation = await _client.getConversation(
          response.conversationId,
        );

        setState(() {
          // Find the temporary summary and update it
          final index = _conversations.indexWhere(
            (c) => c.conversationId == tempId,
          );
          if (index != -1) {
            _conversations[index] = ConversationSummary(
              conversationId: fullConversation.conversationId,
              createdOn: fullConversation.createdOn,
              name: fullConversation.name,
            );
          }

          // Update current conversation if user is still looking at it
          if (_currentConversationId == tempId) {
            _currentConversationId = fullConversation.conversationId;
            _currentConversation = fullConversation;
          }
        });
      } else {
        // 5. Handle Existing Conversation Response: Refresh view if looking at it
        if (_currentConversationId == currentId) {
          // We can just fetch the updated conversation
          final updatedConv = await _client.getConversation(currentId);
          setState(() {
            _currentConversation = updatedConv;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error finding spells: $e');
        // Revert optimistic updates if failed
        if (isNewConversation) {
          setState(() {
            _conversations.removeWhere((c) => c.conversationId == tempId);
            if (_currentConversationId == tempId) {
              _currentConversationId = null;
              _currentConversation = null;
            }
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingRequests.remove(currentId);
          _pendingConversationState.remove(currentId);
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing =
        _currentConversationId != null &&
        _pendingRequests.contains(_currentConversationId);

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
                            isLoading: _isFetching || isProcessing,
                          ),
                        ),
                        InputArea(
                          controller: _promptController,
                          focusNode: _focusNode,
                          isLoading: _isFetching || isProcessing,
                          onSubmit: _submitPrompt,
                          models: _currentConversationId == null ? _models : [],
                          selectedModel: _selectedModel,
                          onModelChanged: (val) {
                            setState(() => _selectedModel = val);
                          },
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
