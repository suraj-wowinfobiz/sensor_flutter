import 'package:flutter/material.dart';

class AppNotificationItem {
  final String title;
  final String message;
  final DateTime time;

  const AppNotificationItem({
    required this.title,
    required this.message,
    required this.time,
  });
}

Future<void> showNotificationsPopup(
  BuildContext context, {
  required List<AppNotificationItem> notifications,
}) async {
  final isLight = Theme.of(context).brightness == Brightness.light;

  String relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_none),
                    SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (notifications.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF5A7386)
                              : const Color(0xFF9DB7D2),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          leading: const Icon(Icons.circle, size: 10),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(item.message),
                          trailing: Text(
                            relativeTime(item.time),
                            style: TextStyle(
                              fontSize: 12,
                              color: isLight
                                  ? const Color(0xFF5A7386)
                                  : const Color(0xFF9DB7D2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
