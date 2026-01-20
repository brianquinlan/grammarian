import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class GrammarianClient {
  final http.Client client;
  final String baseUrl;
  String? authToken;

  GrammarianClient({
    required this.client,
    this.baseUrl = const String.fromEnvironment(
      'API_SERVER_URL',
      defaultValue: '/api',
    ),
  });

  Map<String, String> get _headers => {
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  Future<PromptResponse> prompt(
    String description, {
    String? conversationId,
  }) async {
    final uri = Uri.parse('$baseUrl/prompt');
    
    // Construct the request body
    final Map<String, dynamic> body = {
      'description': description,
      if (conversationId != null) 'conversation_id': conversationId,
      if (const bool.fromEnvironment('FAKE')) 'fake': 'fake',
    };

    final headers = {
      ..._headers,
      'Content-Type': 'application/json',
    };

    final response = await client.post(
      uri, 
      headers: headers,
      body: jsonEncode(body),
    );
    print(response.body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return PromptResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to prompt: ${response.statusCode} ${response.body}');
    }
  }

  Future<ListConversationsResponse> getConversations() async {
    final uri = Uri.parse('$baseUrl/conversations');
    final response = await client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return ListConversationsResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load conversations: ${response.statusCode}');
    }
  }

  Future<Conversation> getConversation(String conversationId) async {
    final uri = Uri.parse('$baseUrl/conversation/$conversationId');
    final response = await client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return Conversation.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load conversation: ${response.statusCode}');
    }
  }
}