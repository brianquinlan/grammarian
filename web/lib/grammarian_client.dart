import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class GrammarianClient {
  final http.Client client;
  final String baseUrl;

  GrammarianClient({
    required this.client,
    this.baseUrl = 'http://127.0.0.1:5000/api',
  });

  Future<List<RingOfTheGrammarianSpell>> findSpells(String description) async {
    final uri = Uri.parse(
      '$baseUrl/grammarian',
    ).replace(queryParameters: {'description': description});
    print(uri);
    final response = await client.get(uri);
    print(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return RingOfTheGrammarianSpell.listFromJson(jsonList);
    } else {
      throw Exception('Failed to load spells: ${response.statusCode}');
    }
  }
}
