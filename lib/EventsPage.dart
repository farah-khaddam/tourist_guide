import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'EventDetailsPage.dart'; // صفحة التفاصيل

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  // دالة لتنسيق التاريخ yyyy/MM/dd
  String formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String year = date.year.toString();
    String month = twoDigits(date.month);
    String day = twoDigits(date.day);
    return "$year/$month/$day";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bgColor = themeProvider.isDark
        ? Colors.black
        : themeProvider.beigeLight;
    final cardColor = themeProvider.isDark
        ? Colors.grey.shade900
        : Colors.white;
    final textColor = themeProvider.isDark
        ? Colors.white
        : Colors.orange.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("الفعاليات"),
        backgroundColor: themeProvider.isDark
            ? themeProvider.orangeDark
            : themeProvider.orangeLight,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('event')
            .orderBy('startDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "لا توجد فعاليات حالياً",
                style: TextStyle(color: textColor),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3 / 4,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'بدون اسم';
              final Timestamp? startTimestamp = data['startDate'];
              final Timestamp? endTimestamp = data['endDate'];
              final DateTime? startDate = startTimestamp?.toDate();
              final DateTime? endDate = endTimestamp?.toDate();
              final String imageUrl = data['imageUrl'] ?? '';
              final now = DateTime.now();
              bool isEnded = endDate != null && endDate.isBefore(now);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailsPage(eventId: docs[index].id),
                    ),
                  );
                },
                child: Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // صورة الفعالية
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey,
                                  child: Icon(
                                    Icons.event,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (startDate != null && endDate != null)
                              Text(
                                "${formatDate(startDate)} - ${formatDate(endDate)}",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            if (isEnded)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "انتهت الفعالية",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
