// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'notifications/notification_storage.dart';
import 'notifications/notification_model.dart';
import 'EventDetailsPage.dart';
import 'location_details_page.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final scaffoldColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text("الإشعارات", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => NotificationStorage.clear(),
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'مسح الكل',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: NotificationStorage.listenable(),
        builder: (context, Box<AppNotification> box, _) {
          final List<AppNotification> items = NotificationStorage.getAllDesc();
          if (items.isEmpty) {
            return const Center(
              child: Text(
                "لا توجد إشعارات حالياً",
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final AppNotification n = items[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final String targetId = n.targetId ?? '';
                    if (targetId.isEmpty) return;
                    if (n.type == NotificationType.event) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailsPage(eventId: targetId),
                        ),
                      );
                      return;
                    }
                    if (n.type == NotificationType.location) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              LocationDetailsPage(locationId: targetId),
                        ),
                      );
                      return;
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title ?? 'إشعار',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.body ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.8),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return '${diff.inMinutes} د';
  if (diff.inHours < 24) return '${diff.inHours} س';
  return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}
