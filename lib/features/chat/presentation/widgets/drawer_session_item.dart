import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/model/chat_session.dart';

class DrawerSessionItem extends StatelessWidget {
  final ChatSession session;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DrawerSessionItem({
    super.key,
    required this.session,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.buddyTeal.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.buddyTeal.withOpacity(0.2))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          Icons.chat_bubble_outline_rounded,
          color: isSelected ? AppTheme.buddyTeal : Colors.white24,
          size: 20,
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.buddyTeal,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.white24,
                ),
                onPressed: onDelete,
              ),
        onTap: onTap,
      ),
    );
  }
}
