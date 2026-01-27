import 'package:flutter/material.dart';
import 'package:grammarian_web/main.dart';
import 'package:grammarian_web/models.dart';
import 'package:grammarian_web/sage_avatar.dart';
import 'package:grammarian_web/spell_card.dart';
import 'package:grammarian_web/usage_widget.dart';

class AssistantMessage extends StatefulWidget {
  final SageOfTheGrammarianAnswer answer;

  const AssistantMessage({super.key, required this.answer});

  @override
  State<AssistantMessage> createState() => _AssistantMessageState();
}

class _AssistantMessageState extends State<AssistantMessage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sageAnswer = widget.answer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SageAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The Sage of the Grammarian',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                UsageWidget(usage: sageAnswer.usage),
                const SizedBox(height: 4),
                SelectionArea(
                  child: Text(
                    sageAnswer.answerDescription,
                    style: const TextStyle(
                      color: AppColors.textLightGray,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                if (sageAnswer.grammarianSpells.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 500,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: sageAnswer.grammarianSpells.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, i) => SizedBox(
                          width: 300,
                          child: SpellCard(
                            spell: sageAnswer.grammarianSpells[i],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
