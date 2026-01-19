import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:grammarian_web/grammarian_client.dart';
import 'package:grammarian_web/models.dart';

class MockClient extends Fake implements http.Client {
  final Future<http.Response> Function(Uri url) handler;
  MockClient(this.handler);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return handler(url);
  }
}

void main() {
  test('prompt returns PromptResponse on 200', () async {
    final client = MockClient((url) async {
      if (url.path == '/api/prompt' &&
          url.queryParameters['description'] == 'test') {
        return http.Response(
          jsonEncode({
            "conversation_id": "123",
            "spells": [
              {
                "original_spell_name": "Test Spell",
                "grammarian_spell": {
                  "name": "Test Spell",
                  "school": "Evocation",
                  "level": "3rd",
                  "casting_time": "1 action",
                  "range": "150 feet",
                  "components": "V, S, M",
                  "duration": "Instantaneous",
                  "description": "A test spell.",
                },
              },
            ],
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final grammarianClient = GrammarianClient(client: client);
    final response = await grammarianClient.prompt('test');

    expect(response, isA<PromptResponse>());
    expect(response.conversationId, '123');
    expect(response.spells.length, 1);
    expect(response.spells.first.originalSpellName, 'Test Spell');
  });

  test('getConversations returns ListConversationsResponse on 200', () async {
    final client = MockClient((url) async {
      if (url.path == '/api/conversations') {
        return http.Response(
          jsonEncode({
            "conversations": [
              {
                "conversation_id": "c1",
                "created_on": "2023-10-27T10:00:00.000000",
                "name": "Conv 1",
              },
            ],
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final grammarianClient = GrammarianClient(client: client);
    final response = await grammarianClient.getConversations();

    expect(response, isA<ListConversationsResponse>());
    expect(response.conversations.length, 1);
    expect(response.conversations.first.conversationId, 'c1');
  });

  test('getConversation returns Conversation used Dialog on 200', () async {
    final client = MockClient((url) async {
      if (url.path == '/api/conversation/c1') {
        return http.Response(
          jsonEncode({
            "conversation_id": "c1",
            "created_on": "2023-10-27T10:00:00.000000",
            "name": "Conv 1",
            "model": "gpt-4",
            "dialog": [
              {"text": "hello"},
              {
                "spells": [
                  {
                    "original_spell_name": "Test Spell",
                    "grammarian_spell": {
                      "name": "Test Spell",
                      "school": "Evocation",
                      "level": "3rd",
                      "casting_time": "1 action",
                      "range": "150 feet",
                      "components": "V, S, M",
                      "duration": "Instantaneous",
                      "description": "A test spell.",
                    },
                  },
                ],
              },
            ],
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final grammarianClient = GrammarianClient(client: client);
    final response = await grammarianClient.getConversation('c1');

    expect(response, isA<Conversation>());
    expect(response.conversationId, 'c1');
    expect(response.dialog.length, 2);
    expect(response.dialog[0], isA<UserPrompt>());
    expect((response.dialog[0] as UserPrompt).text, 'hello');
    expect(response.dialog[1], isA<AppResponse>());
    expect((response.dialog[1] as AppResponse).spells.length, 1);
  });
}
