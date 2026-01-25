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

class SageOfTheGrammarianAnswer extends ConversationItem {
  final String answerDescription;
  final List<RingOfTheGrammarianSpell> grammarianSpells;

  SageOfTheGrammarianAnswer({
    required this.answerDescription,
    required this.grammarianSpells,
  });

  factory SageOfTheGrammarianAnswer.fromJson(Map<String, dynamic> json) {
    return SageOfTheGrammarianAnswer(
      answerDescription: json['answer_description'] as String,
      grammarianSpells: RingOfTheGrammarianSpell.listFromJson(
        json['grammarian_spells'] as List<dynamic>,
      ),
    );
  }
}

class PromptResponse {
  final String conversationId;
  final SageOfTheGrammarianAnswer sageAnswer;

  PromptResponse({required this.conversationId, required this.sageAnswer});

  factory PromptResponse.fromJson(Map<String, dynamic> json) {
    return PromptResponse(
      conversationId: json['conversation_id'] as String,
      sageAnswer: SageOfTheGrammarianAnswer.fromJson(
        json['sage_answer'] as Map<String, dynamic>,
      ),
    );
  }
}

class ConversationSummary {
  final String conversationId;
  final DateTime createdOn;
  final String name;

  ConversationSummary({
    required this.conversationId,
    required this.createdOn,
    required this.name,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      conversationId: json['conversation_id'] as String,
      createdOn: DateTime.parse(json['created_on'] as String),
      name: json['name'] as String,
    );
  }
}

class ListConversationsResponse {
  final List<ConversationSummary> conversations;

  ListConversationsResponse({required this.conversations});

  factory ListConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ListConversationsResponse(
      conversations: (json['conversations'] as List<dynamic>)
          .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

abstract class ConversationItem {
  ConversationItem();

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('utterance')) {
      return AdventurerPrompt.fromJson(json);
    } else if (json.containsKey('answer_description')) {
      return SageOfTheGrammarianAnswer.fromJson(json);
    }
    throw FormatException('Unknown conversation item type: ${json.keys}');
  }
}

class AdventurerPrompt extends ConversationItem {
  final String utterance;

  AdventurerPrompt({required this.utterance});

  factory AdventurerPrompt.fromJson(Map<String, dynamic> json) {
    return AdventurerPrompt(utterance: json['utterance'] as String);
  }
}

class Conversation {
  final String conversationId;
  final DateTime createdOn;
  final String name;
  final String model;
  final List<ConversationItem> dialog;

  Conversation({
    required this.conversationId,
    required this.createdOn,
    required this.name,
    required this.model,
    required this.dialog,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversation_id'] as String,
      createdOn: DateTime.parse(json['created_on'] as String),
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      dialog:
          (json['dialog'] as List<dynamic>?)
              ?.map((e) => ConversationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ModelInfo {
  final String name;
  final String model;

  ModelInfo({required this.name, required this.model});

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      name: json['name'] as String,
      model: json['model'] as String,
    );
  }
}

class ListModelsResponse {
  final List<ModelInfo> models;

  ListModelsResponse({required this.models});

  factory ListModelsResponse.fromJson(Map<String, dynamic> json) {
    return ListModelsResponse(
      models: (json['models'] as List<dynamic>)
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
