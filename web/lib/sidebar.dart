import 'package:flutter/material.dart';
import 'package:grammarian_web/main.dart';
import 'package:grammarian_web/models.dart';

class Sidebar extends StatelessWidget {
  final List<ConversationSummary> conversations;
  final String? currentId;
  final Function(String) onSelect;
  final VoidCallback onNew;

  const Sidebar({
    super.key,
    required this.conversations,
    required this.currentId,
    required this.onSelect,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    // Group conversations (simplification)
    final now = DateTime.now();
    final today = conversations
        .where(
          (c) =>
              c.createdOn.year == now.year &&
              c.createdOn.month == now.month &&
              c.createdOn.day == now.day,
        )
        .toList();
    final others = conversations.where((c) => !today.contains(c)).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0e0c11),
        border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: onNew,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.surfaceBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'New Scenario',
                      style: TextStyle(
                        color: AppColors.textLightGray,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                if (today.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        color: Color(0xFF554b60),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...today.map((c) => _buildNavItem(c, context)),
                ],
                if (others.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'HISTORY',
                      style: TextStyle(
                        color: Color(0xFF554b60),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...others.map((c) => _buildNavItem(c, context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(ConversationSummary summary, BuildContext context) {
    final isSelected = summary.conversationId == currentId;
    return InkWell(
      onTap: () => onSelect(summary.conversationId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.surfaceBorder.withOpacity(0.4),
                border: Border.all(
                  color: AppColors.surfaceBorder.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF554b60),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                summary.name.isEmpty ? 'Untitled' : summary.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFab9db9),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
