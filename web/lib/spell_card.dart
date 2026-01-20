import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grammarian_web/main.dart';
import 'package:grammarian_web/models.dart';

class SpellCard extends StatelessWidget {
  final RingOfTheGrammarianSpell spell;

  const SpellCard({super.key, required this.spell});

  @override
  Widget build(BuildContext context) {
    final gSpell = spell.grammarianSpell;

    // Determine color based on school (mock-like colors)
    Color iconColor = Colors.blue.shade300;
    Color textColor = Colors.blue.shade400;
    IconData iconData = Icons.auto_fix_high;

    switch (gSpell.school) {
      case School.abjuration:
        iconColor = Colors.blueGrey.shade300;
        textColor = Colors.blueGrey.shade400;
        iconData = Icons.security;
        break;
      case School.conjuration:
        iconColor = Colors.yellow.shade200;
        textColor = Colors.yellow.shade400;
        iconData = Icons.light_mode;
        break;
      case School.divination:
        iconColor = Colors.cyan.shade300;
        textColor = Colors.cyan.shade400;
        iconData = Icons.visibility;
        break;
      case School.enchantment:
        iconColor = Colors.pink.shade300;
        textColor = Colors.pink.shade400;
        iconData = Icons.favorite;
        break;
      case School.evocation:
        iconColor = Colors.blue.shade300;
        textColor = Colors.blue.shade400;
        iconData = Icons.flash_on;
        break;
      case School.illusion:
        iconColor = Colors.deepPurple.shade300;
        textColor = Colors.deepPurple.shade400;
        iconData = Icons.blur_on;
        break;
      case School.necromancy:
        iconColor = Colors.purple.shade300;
        textColor = Colors.purple.shade400;
        iconData = Icons.local_hospital;
        break;
      case School.transmutation:
        iconColor = Colors.orange.shade300;
        textColor = Colors.orange.shade400;
        iconData = Icons.transform;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gSpell.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${gSpell.level.jsonValue} ${gSpell.school.jsonValue}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: 20,
                  color: AppColors.textGray,
                ),
                tooltip: 'Copy Markdown',
                onPressed: () {
                  final markdown =
                      '''
### ${gSpell.name}
*${gSpell.level.jsonValue} ${gSpell.school.jsonValue}*

**Casting Time:** ${gSpell.castingTime}
**Range:** ${gSpell.range}
**Components:** ${gSpell.components}
**Duration:** ${gSpell.duration}
**Original Spell:** ${spell.originalSpellName}

${gSpell.description}
''';
                  Clipboard.setData(ClipboardData(text: markdown));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Casting Time', gSpell.castingTime),
          _buildDetailRow('Range', gSpell.range),
          _buildDetailRow('Components', gSpell.components),
          _buildDetailRow('Duration', gSpell.duration),
          const SizedBox(height: 12),
          Divider(color: AppColors.surfaceBorder.withOpacity(0.5)),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                gSpell.description,
                style: const TextStyle(
                  color: Color(0xFFd0c6dc),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textLightGray,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
