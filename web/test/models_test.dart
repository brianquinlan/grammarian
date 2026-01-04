import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:grammarian_web/models.dart';

void main() {
  test('Parses spell JSON correctly', () {
    const jsonString = '''
[
  {
    "original_spell_name": "Guiding Bolt",
    "grammarian_spell": {
      "name": "Guising Bolt",
      "school": "Illusion",
      "level": "1st",
      "casting_time": "1 action",
      "range": "120 feet",
      "components": "V, S",
      "duration": "10 minutes",
      "description": "A flash of light streaks toward a creature within range. On a hit, or if the target is willing, the target is instantly covered in an illusion that makes them appear as a mundane object of similar size (such as a statue, a bush, or a barrel) appropriate to the environment. The illusion holds up to visual inspection but fails if touched. An unwilling creature can make a Wisdom saving throw to avoid the effect."
    }
  },
  {
    "original_spell_name": "Hold Person",
    "grammarian_spell": {
      "name": "Fold Person",
      "school": "Transmutation",
      "level": "2nd",
      "casting_time": "1 action",
      "range": "60 feet",
      "components": "V, S, M (a small piece of paper)",
      "duration": "Concentration, up to 1 minute",
      "description": "Choose a humanoid that you can see within range. The target must succeed on a Wisdom saving throw or be magically folded into a small, flat square of flesh and clothing, roughly 6 inches on a side. The target is incapacitated and has a speed of 0. It can be picked up and hidden easily. At the end of each of its turns, the target can make another Wisdom saving throw. On a success, the spell ends."
    }
  },
  {
    "original_spell_name": "Aid",
    "grammarian_spell": {
      "name": "Hid",
      "school": "Illusion",
      "level": "3rd",
      "casting_time": "1 action",
      "range": "Touch",
      "components": "V, S, M (a piece of cloth)",
      "duration": "Concentration, up to 1 hour",
      "description": "You touch a willing creature or object. The target becomes invisible and leaves no physical tracks or scent. It gains a +10 bonus to Dexterity (Stealth) checks. The spell ends if the target attacks or casts a spell."
    }
  }
]
''';

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    final spells = RingOfTheGrammarianSpell.listFromJson(jsonList);

    expect(spells.length, 3);

    final s1 = spells[0];
    expect(s1.originalSpellName, 'Guiding Bolt');
    expect(s1.grammarianSpell.name, 'Guising Bolt');
    expect(s1.grammarianSpell.school, School.illusion);
    expect(s1.grammarianSpell.level, Level.first);
    expect(s1.grammarianSpell.castingTime, '1 action');
    expect(s1.grammarianSpell.range, '120 feet');
    expect(s1.grammarianSpell.components, 'V, S');
    expect(s1.grammarianSpell.duration, '10 minutes');
    expect(
      s1.grammarianSpell.description,
      startsWith('A flash of light streaks toward a creature within range.'),
    );

    final s2 = spells[1];
    expect(s2.originalSpellName, 'Hold Person');
    expect(s2.grammarianSpell.name, 'Fold Person');
    expect(s2.grammarianSpell.school, School.transmutation);
    expect(s2.grammarianSpell.level, Level.second);

    final s3 = spells[2];
    expect(s3.originalSpellName, 'Aid');
    expect(s3.grammarianSpell.name, 'Hid');
    expect(s3.grammarianSpell.school, School.illusion);
    expect(s3.grammarianSpell.level, Level.third);
  });
}
