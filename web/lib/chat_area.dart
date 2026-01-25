import 'package:flutter/material.dart';
import 'package:grammarian_web/assistant_message.dart';
import 'package:grammarian_web/main.dart';
import 'package:grammarian_web/models.dart';
import 'package:grammarian_web/sage_avatar.dart';

class ChatArea extends StatefulWidget {
  final Conversation? conversation;
  final bool isLoading;
  final List<ModelInfo> models;

  const ChatArea({
    super.key,
    required this.conversation,
    required this.isLoading,
    this.models = const [],
  });

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(ChatArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversation != oldWidget.conversation ||
        widget.isLoading != oldWidget.isLoading) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getFriendlyModelName(String modelId) {
    try {
      return widget.models.firstWhere((m) => m.model == modelId).name;
    } catch (_) {
      return modelId;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.conversation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/sage.png', width: 250, height: 250),
            const SizedBox(height: 16),
            const Text(
              'The Ring of the Grammarian allows you to change one letter '
              'of a spell\'s name to create a new effect.\nDescribe a '
              'situation, and I will suggest the perfect Grammarian '
              'spell to help.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            'Mode: ${_getFriendlyModelName(widget.conversation!.model)}',
            style: TextStyle(
              color: AppColors.textGray.withValues(alpha: 0.3),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            itemCount: widget.conversation!.dialog.length + (widget.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= widget.conversation!.dialog.length) {
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

              final item = widget.conversation!.dialog[index];
              if (item is AdventurerPrompt) {
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
                            color: AppColors.surfaceCard.withValues(
                              alpha: 0.6,
                            ), // Glassy
                            border: Border.all(
                              color: AppColors.surfaceBorder.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(2),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: SelectionArea(
                            child: Text(
                              item.utterance,
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
              } else if (item is SageOfTheGrammarianAnswer) {
                return AssistantMessage(answer: item);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
