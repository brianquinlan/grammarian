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
  test('findSpells returns list of spells on 200', () async {
    final client = MockClient((url) async {
      // Check correct URL and params
      if (url.path == '/grammarian' &&
          url.queryParameters['description'] == 'test') {
        return http.Response(
          jsonEncode([
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
          ]),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final grammarianClient = GrammarianClient(client: client);
    final spells = await grammarianClient.findSpells('test');

    expect(spells, isA<List<RingOfTheGrammarianSpell>>());
    expect(spells.length, 1);
    expect(spells.first.originalSpellName, 'Test Spell');
    expect(spells.first.grammarianSpell.name, 'Test Spell');
  });

  test('findSpells throws exception on non-200', () async {
    final client = MockClient((url) async {
      return http.Response('Internal Server Error', 500);
    });

    final grammarianClient = GrammarianClient(client: client);

    expect(grammarianClient.findSpells('test'), throwsException);
  });
}
