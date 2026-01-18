import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class GrammarianClient {
  final http.Client client;
  final String baseUrl;

  GrammarianClient({
    required this.client,
    this.baseUrl = const String.fromEnvironment(
      'API_SERVER_URL',
      defaultValue: '/api',
    ),
  });

  Future<PromptResponse> prompt(
    String description, {
    String? conversationId,
  }) async {
    final uri = Uri.parse('$baseUrl/prompt').replace(
      queryParameters: {
        'description': description,
        if (conversationId != null) 'conversation_id': conversationId,
        if (const bool.fromEnvironment('FAKE')) 'fake': 'fake',
      },
    );
    print(uri);
    final response = await client.get(uri);
    print(response.body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return PromptResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to prompt: ${response.statusCode}');
    }
  }
}
