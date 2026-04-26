import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grammarian_web/chat_area.dart';
import 'package:grammarian_web/input_area.dart';
import 'package:grammarian_web/sidebar.dart';
import 'package:grammarian_web/top_header.dart';
import 'package:grammarian_web/footer.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'grammarian_client.dart';
import 'models.dart';
import 'login_page.dart';
import 'firebase_options.dart';
import 'package:uuid/uuid.dart';

// --- Theme Constants ---
class AppColors {
  static const primary = Color(0xFF9333ea); // Updated from login_page
  static const primaryHover = Color(0xFF7e22ce);
  static const backgroundDark = Color(0xFF0f0c16);
  static const surfaceDark = Color(0xFF140f23); // Slightly lighter than bg
  static const surfaceCard = Color(0xFF1e182a); // For cards/inputs
  static const surfaceBorder = Color(0xFF3b3047);
  static const textWhite = Colors.white;
  static const textGray = Color(0xFF9ca3af); // standard gray-400
  static const textLightGray = Color(0xFFe5e7eb); // standard gray-200
  static const backgroundLight = Color(0xFFf7f6f8); // Kept for safety, unused?
}

// ... existing main() and MyApp ...
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    }
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF131117),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Application Initialization Failed',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Firebase initialization failed: $e',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  return const MainLayout();
                }
                return const LoginPage();
              },
            );
          },
        ),
        GoRoute(
          path: '/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return MainLayout(initialConversationId: id);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
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
    );
  }
}

class MainLayout extends StatefulWidget {
  final String? initialConversationId;
  const MainLayout({super.key, this.initialConversationId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // ... existing state variables ...
  final _client = GrammarianClient(client: http.Client());
  List<ConversationSummary> _conversations = [];
  List<ModelInfo> _models = [];
  Conversation? _currentConversation;
  String? _currentConversationId;
  String? _selectedModel;
  final Set<String> _pendingRequests = {};
  final Map<String, Conversation> _pendingConversationState = {};
  bool _isFetching = false;
  bool _geekMode = false;
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

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialConversationId != oldWidget.initialConversationId) {
      if (widget.initialConversationId != null) {
        if (_currentConversationId != widget.initialConversationId) {
          _selectConversation(widget.initialConversationId!);
        }
      } else {
        _createNewConversation();
      }
    }
  }

  // ... existing methods (_initAndLoad, _loadConversations, _loadModels, _selectConversation, _createNewConversation, _submitPrompt, _showError) ...
  Future<void> _initAndLoad() async {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      if (user != null) {
        try {
          final token = await user.getIdToken();
          _client.authToken = token;
          await Future.wait([
            _loadConversations(),
            _loadModels(),
            _loadSettings(),
          ]);
        } catch (e) {
          if (mounted) _showError('Error initializing session: $e');
        }
      } else {
        _client.authToken = null;
        setState(() {
          _conversations = [];
        });
        await _loadModels();
      }
    });

    if (widget.initialConversationId != null) {
      _selectConversation(widget.initialConversationId!);
    } else {
      _createNewConversation();
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

  Future<void> _loadSettings() async {
    try {
      final settings = await _client.getSettings();
      if (mounted) {
        setState(() {
          _geekMode = settings.geekMode;
        });
      }
    } catch (e) {
      // Silently fail for settings, or log debug
      debugPrint('Error loading settings: $e');
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
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  void _createNewConversation() {
    setState(() {
      _currentConversationId = null;
      _currentConversation = null;
      _promptController.clear();
      // Reset model selection to default (first available)
      if (_models.isNotEmpty) {
        _selectedModel = _models.first.model;
      }
    });
  }

  void _onSelectConversationFromSidebar(String id) {
    context.go('/$id');
  }

  void _onNewConversationFromSidebar() {
    context.go('/');
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
          model: _selectedModel ?? '',
          ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
          dialog: [AdventurerPrompt(utterance: text)],
        );
      }
      _promptController.clear();
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
          _selectedModel,
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
            context.go('/${fullConversation.conversationId}');
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
            _promptController.text = text;
          });
        } else {
          setState(() {
            _promptController.text = text;
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
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient and Blobs
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color.fromRGBO(17, 24, 39, 0.4),
                    Color.fromRGBO(17, 24, 39, 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.shade900.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main UI Layer
          Column(
            children: [
              TopHeader(onSettingsChanged: _loadSettings),
              Expanded(
                child: Row(
                  children: [
                    // Sidebar
                    if (MediaQuery.of(context).size.width > 768)
                      SizedBox(
                        width: 280,
                        child: Sidebar(
                          conversations: _conversations,
                          currentId: _currentConversationId,
                          onSelect: _onSelectConversationFromSidebar,
                          onNew: _onNewConversationFromSidebar,
                        ),
                      ),
                    // Main Content
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ChatArea(
                              conversation: _currentConversation,
                              isLoading: isProcessing,
                              models: _models,
                              geekMode: _geekMode,
                            ),
                          ),
                          if (!isProcessing)
                            InputArea(
                              controller: _promptController,
                              focusNode: _focusNode,
                              isLoading: _isFetching || isProcessing,
                              readOnly: FirebaseAuth.instance.currentUser == null ||
                                  (_currentConversation != null &&
                                      _currentConversation!.ownerId != FirebaseAuth.instance.currentUser?.uid),
                              onSubmit: _submitPrompt,
                              models: _currentConversationId == null
                                  ? _models
                                  : [],
                              selectedModel: _selectedModel,
                              onModelChanged: (val) {
                                setState(() => _selectedModel = val);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Footer
          const FooterLink(),
        ],
      ),
    );
  }
}
