import 'package:flutter/material.dart';
import 'package:grammarian_web/assistant_message.dart';
import 'package:grammarian_web/main.dart';
import 'package:grammarian_web/models.dart';
import 'package:grammarian_web/sage_avatar.dart';

class ChatArea extends StatelessWidget {
  final Conversation? conversation;
  final bool isLoading;

  const ChatArea({
    super.key,
    required this.conversation,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/ring.png', width: 200, height: 200),
            const SizedBox(height: 16),
            const Text(
              'Sage of the Grammarian',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The Ring of the Grammarian allows you to change one letter ' +
                  'of a spell\'s name to create a new effect.\nDescribe a ' +
                  'situation, and I will suggest the perfect Grammarian ' +
                  'spell to help.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, height: 1.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      itemCount: conversation!.dialog.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= conversation!.dialog.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Row(
              children: [
                SageAvatar(),
                SizedBox(width: 16),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          );
        }

        final item = conversation!.dialog[index];
        if (item is UserPrompt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border.all(color: AppColors.surfaceBorder),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(2),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: SelectionArea(
                      child: Text(
                        item.text,
                        style: const TextStyle(
                          color: AppColors.textLightGray,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (item is AppResponse) {
          return AssistantMessage(response: item);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
