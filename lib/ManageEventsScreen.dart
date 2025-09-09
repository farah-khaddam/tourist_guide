// ManageEventsScreen.dart
import 'package:TRIPSY/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EditEventScreen.dart'; // صفحة تعديل الفعالية

class ManageEventsScreen extends StatelessWidget {
  const ManageEventsScreen({super.key});

  Future<void> _deleteEvent(String eventId, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من حذف هذه الفعالية؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('event').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حذف الفعالية بنجاح")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إدارة الفعاليات"),
          backgroundColor: AppTheme.orangeLight,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('event').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final events = snapshot.data!.docs;

            if (events.isEmpty) {
              return const Center(child: Text("لا توجد فعاليات حالياً."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final doc = events[index];
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? "بدون اسم";

                // التواريخ مع التحقق من null
                final startDate = data['startDate'] != null
                    ? (data['startDate'] as Timestamp).toDate()
                    : null;
                final endDate = data['endDate'] != null
                    ? (data['endDate'] as Timestamp).toDate()
                    : null;

                String dateText;
                if (startDate != null && endDate != null) {
                  dateText =
                      "من: ${startDate.toLocal().toString().split(' ')[0]} إلى: ${endDate.toLocal().toString().split(' ')[0]}";
                } else {
                  dateText = "التاريخ غير محدد";
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text(dateText),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.orangeLight),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditEventScreen(
                                  eventId: doc.id,
                                  existingData: data,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.orangeLight),
                          onPressed: () => _deleteEvent(doc.id, context),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
