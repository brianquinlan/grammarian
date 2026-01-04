import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class GrammarianClient {
  final http.Client client;
  final String baseUrl;

  GrammarianClient({
    required this.client,
    this.baseUrl = 'http://localhost:5000',
  });

  Future<List<RingOfTheGrammarianSpell>> findSpells(String description) async {
    final uri = Uri.parse(
      '$baseUrl/grammarian',
    ).replace(queryParameters: {'description': description});

    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return RingOfTheGrammarianSpell.listFromJson(jsonList);
    } else {
      throw Exception('Failed to load spells: ${response.statusCode}');
    }
  }
}
