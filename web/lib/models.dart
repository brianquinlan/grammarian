enum School {
  abjuration('Abjuration'),
  conjuration('Conjuration'),
  divination('Divination'),
  enchantment('Enchantment'),
  evocation('Evocation'),
  illusion('Illusion'),
  necromancy('Necromancy'),
  transmutation('Transmutation');

  final String jsonValue;
  const School(this.jsonValue);

  static School fromJson(String value) {
    return School.values.firstWhere(
      (e) => e.jsonValue == value,
      orElse: () => throw ArgumentError('Unknown school: $value'),
    );
  }
}

enum Level {
  cantrip('Cantrip'),
  first('1st'),
  second('2nd'),
  third('3rd'),
  fourth('4th'),
  fifth('5th'),
  sixth('6th'),
  seventh('7th'),
  eighth('8th'),
  ninth('9th');

  final String jsonValue;
  const Level(this.jsonValue);

  static Level fromJson(String value) {
    return Level.values.firstWhere(
      (e) => e.jsonValue == value,
      orElse: () => throw ArgumentError('Unknown level: $value'),
    );
  }
}

class Spell {
  final String name;
  final School school;
  final Level level;
  final String castingTime;
  final String range;
  final String components;
  final String duration;
  final String description;

  Spell({
    required this.name,
    required this.school,
    required this.level,
    required this.castingTime,
    required this.range,
    required this.components,
    required this.duration,
    required this.description,
  });

  factory Spell.fromJson(Map<String, dynamic> json) {
    return Spell(
      name: json['name'] as String,
      school: School.fromJson(json['school'] as String),
      level: Level.fromJson(json['level'] as String),
      castingTime: json['casting_time'] as String,
      range: json['range'] as String,
      components: json['components'] as String,
      duration: json['duration'] as String,
      description: json['description'] as String,
    );
  }
}

class RingOfTheGrammarianSpell {
  final String originalSpellName;
  final Spell grammarianSpell;

  RingOfTheGrammarianSpell({
    required this.originalSpellName,
    required this.grammarianSpell,
  });

  factory RingOfTheGrammarianSpell.fromJson(Map<String, dynamic> json) {
    return RingOfTheGrammarianSpell(
      originalSpellName: json['original_spell_name'] as String,
      grammarianSpell: Spell.fromJson(
        json['grammarian_spell'] as Map<String, dynamic>,
      ),
    );
  }

  static List<RingOfTheGrammarianSpell> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map(
          (e) => RingOfTheGrammarianSpell.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}
