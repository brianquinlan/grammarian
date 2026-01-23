import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grammarian_web/main.dart';
import 'package:grammarian_web/models.dart';

class InputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final Function(String) onSubmit;
  final List<ModelInfo> models;
  final String? selectedModel;
  final ValueChanged<String?>? onModelChanged;

  const InputArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSubmit,
    this.models = const [],
    this.selectedModel,
    this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.backgroundDark, Colors.transparent],
          stops: [0.5, 1.0],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.surfaceBorder),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.enter): () {
                      if (!isLoading) onSubmit(controller.text);
                    },
                  },
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    readOnly: isLoading,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText:
                          'Ask for a spell, describe a scenario, or check rules...',
                      hintStyle: TextStyle(color: AppColors.textGray),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    onSubmitted: (text) {
                      if (!isLoading) onSubmit(text);
                    },
                  ),
                ),
                if (models.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.surfaceBorder.withOpacity(0.5),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedModel,
                              dropdownColor: AppColors.surfaceCard,
                              style: const TextStyle(
                                color: AppColors.textLightGray,
                                fontSize: 13,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textGray,
                                size: 18,
                              ),
                              isDense: true,
                              items: models.map((m) {
                                return DropdownMenuItem(
                                  value: m.model,
                                  child: Text(m.name),
                                );
                              }).toList(),
                              onChanged: onModelChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
