import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:grammarian_web/grammarian_client.dart';
import 'package:grammarian_web/models.dart';

class MockClient extends Fake implements http.Client {
  final Future<http.Response> Function(Uri url, {Object? body}) handler;
  MockClient(this.handler);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return handler(url);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return handler(url, body: body);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return handler(url, body: body);
  }
}

void main() {
  test('createConversation returns PromptResponse on 200', () async {
    final client = MockClient((url, {body}) async {
      if (url.path == '/api/conversation/123') {
        // PUT request logic check
        final bodyMap = jsonDecode(body as String);
        if (bodyMap['description'] == 'test' &&
            bodyMap['model'] == 'test-model') {
          return http.Response(
            jsonEncode({
              "conversation_id": "123",
              "sage_answer": {
                "answer_description": "Here is a test spell.",
                "grammarian_spells": [
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
            }),
            200,
          );
        }
      }
      return http.Response('Not Found', 404);
    });

    final grammarianClient = GrammarianClient(client: client);
    final response = await grammarianClient.createConversation(
      '123',
      'test',
      'test-model',
    );

    expect(response, isA<PromptResponse>());
    expect(response.conversationId, '123');
    expect(response.sageAnswer.grammarianSpells.length, 1);
  });

  test('updateConversation returns PromptResponse on 200', () async {
    final client = MockClient((url, {body}) async {
      if (url.path == '/api/conversation/123') {
        // POST request logic check
        final bodyMap = jsonDecode(body as String);
        if (bodyMap['description'] == 'test update') {
          return http.Response(
            jsonEncode({
              "conversation_id": "123",
              "sage_answer": {
                "answer_description": "Here is a test spell.",
                "grammarian_spells": [],
              },
            }),
            200,
          );
        }
      }
      return http.Response('Not Found', 404);
    });

    final grammarianClient = GrammarianClient(client: client);
    final response = await grammarianClient.updateConversation(
      '123',
      'test update',
    );

    expect(response, isA<PromptResponse>());
    expect(response.conversationId, '123');
    expect(response.sageAnswer.grammarianSpells.length, 0);
  });

  test('getConversations returns ListConversationsResponse on 200', () async {
    final client = MockClient((url, {body}) async {
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
    final client = MockClient((url, {body}) async {
      if (url.path == '/api/conversation/c1') {
        return http.Response(
          jsonEncode({
            "conversation_id": "c1",
            "created_on": "2023-10-27T10:00:00.000000",
            "name": "Conv 1",
            "model": "gpt-4",
            "dialog": [
              {"utterance": "hello"},
              {
                "answer_description": "Here is a test spell.",
                "grammarian_spells": [
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
    expect(response.dialog[0], isA<AdventurerPrompt>());
    expect((response.dialog[0] as AdventurerPrompt).utterance, 'hello');
    expect(response.dialog[1], isA<SageOfTheGrammarianAnswer>());
    expect(
      (response.dialog[1] as SageOfTheGrammarianAnswer).grammarianSpells.length,
      1,
    );
  });
}
