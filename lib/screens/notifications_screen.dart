import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final notes = app.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notes.any((n) => n['read'] != true))
            TextButton(
              onPressed: () => app.markAllNotificationsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notes.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              message: 'No notifications yet',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (_, i) {
                final n = notes[i];
                final read = n['read'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CreamCard(
                    onTap: () {
                      if (!read) app.markNotificationRead(n['id'] as String);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _iconForType(n['type'] as String? ?? ''),
                          color: read ? AppColors.creamMuted : AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n['title'] as String? ?? '',
                                style: TextStyle(
                                  fontWeight: read
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: AppColors.cream,
                                ),
                              ),
                              Text(
                                n['body'] as String? ?? '',
                                style: const TextStyle(
                                  color: AppColors.creamMuted,
                                  fontSize: 13,
                                ),
                              ),
                              if (n['createdAt'] != null)
                                Text(
                                  _formatTime(n['createdAt'] as String),
                                  style: const TextStyle(
                                    color: AppColors.creamMuted,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accepted':
        return Icons.check_circle;
      case 'group_message':
        return Icons.chat;
      case 'shared_note':
        return Icons.note_add;
      case 'study_complete':
        return Icons.timer;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(String iso) {
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }
}
