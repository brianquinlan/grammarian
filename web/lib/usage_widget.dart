import 'package:flutter/material.dart';
import 'package:grammarian_web/main.dart';

class UsageWidget extends StatelessWidget {
  final Map<String, Object> usage;

  const UsageWidget({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    if (usage.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = usage.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: sortedEntries.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.key}: ',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  color: AppColors.textLightGray,
                  fontSize: 12,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
