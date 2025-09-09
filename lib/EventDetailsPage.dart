import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'location_details_page.dart';

class EventDetailsPage extends StatelessWidget {
  final String eventId;
  const EventDetailsPage({super.key, required this.eventId});

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
    final bgColor = themeProvider.isDark ? Colors.black : themeProvider.beigeLight;
    final textColor = themeProvider.isDark ? Colors.white : themeProvider.orangeLight;
    final cardColor = themeProvider.isDark ? Colors.grey.shade900 : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl, // جعل الصفحة من اليمين لليسار
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text("تفاصيل الفعالية"),
          backgroundColor: themeProvider.isDark ? themeProvider.orangeDark : themeProvider.orangeLight,
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('event').doc(eventId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!.data() as Map<String, dynamic>;

            final String name = data['name'] ?? '';
            final String description = data['description'] ?? '';
            final String contactNumber = data['contactNumber'] ?? '';
            final Timestamp? startTimestamp = data['startDate'];
            final Timestamp? endTimestamp = data['endDate'];
            final String imageUrl = data['imageUrl'] ?? '';
            final List<dynamic> locationIds = data['locationIds'] ?? [];

            final DateTime? startDate = startTimestamp?.toDate();
            final DateTime? endDate = endTimestamp?.toDate();
            final now = DateTime.now();
            bool isEnded = endDate != null && endDate.isBefore(now);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // صور الفعالية
                  // صورة الفعالية الرئيسية
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey,
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.white, size: 40),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                  // بطاقة اسم الفعالية
                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        name,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // بطاقة التواريخ
                  if (startDate != null && endDate != null)
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "التواريخ:",
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${formatDate(startDate)} - ${formatDate(endDate)}",
                              style: TextStyle(color: textColor.withOpacity(0.8)),
                            ),
                            if (isEnded)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "انتهت الفعالية",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // بطاقة الوصف
                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        description,
                        style: TextStyle(color: textColor, fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // بطاقة رقم الاتصال
                  if (contactNumber.isNotEmpty)
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          "رقم الاتصال: $contactNumber",
                          style: TextStyle(color: textColor, fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // بطاقة المواقع المرتبطة
                  if (locationIds.isNotEmpty)
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "المواقع المرتبطة:",
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: locationIds.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 3 / 4,
                              ),
                              itemBuilder: (context, index) {
                                final locId = locationIds[index];
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('location').doc(locId).get(),
                                  builder: (context, locSnap) {
                                    if (!locSnap.hasData) {
                                      return Container(
                                        color: cardColor,
                                        child: const Center(child: CircularProgressIndicator()),
                                      );
                                    }
                                    final locData = locSnap.data!.data() as Map<String, dynamic>;
                                    final locName = locData['name'] ?? 'بدون اسم';
                                    final List<String> locImages = List<String>.from(locData['images'] ?? []);
                                    final locImageUrl = locImages.isNotEmpty ? locImages.first : '';

                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LocationDetailsPage(locationId: locId),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        color: cardColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                child: locImageUrl.isNotEmpty
                                                    ? Image.network(locImageUrl, width: double.infinity, fit: BoxFit.cover)
                                                    : Container(
                                                        color: Colors.grey,
                                                        child: Icon(Icons.location_on, size: 40, color: Colors.white),
                                                      ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                locName,
                                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
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
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
