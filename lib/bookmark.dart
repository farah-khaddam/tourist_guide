// bookmark.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_details_page.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('المفضلة'),
        ),
        body: const Center(
          child: Text('يجب تسجيل الدخول لعرض المفضلة.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookmarks')
            .where('userId', isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Firestore error: ${snapshot.error}');
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل المفضلة:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final bookmarks = snapshot.data!.docs;

            if (bookmarks.isEmpty) {
              return const Center(
                child: Text('لا يوجد معالم محفوظة بعد.'),
              );
            }

            final locationIds = bookmarks
                .map((b) => (b.data() as Map<String, dynamic>)['locationId'] as String)
                .toList();

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('location')
                  .where(FieldPath.documentId, whereIn: locationIds)
                  .get(),
              builder: (context, locationsSnap) {
                if (locationsSnap.hasError) {
                  print('Error fetching locations: ${locationsSnap.error}');
                  return Center(
                    child: Text(
                      'حدث خطأ أثناء جلب بيانات المواقع:\n${locationsSnap.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!locationsSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final locationsMap = {
                  for (var doc in locationsSnap.data!.docs)
                    doc.id: doc.data() as Map<String, dynamic>
                };

                return ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    try {
                      final bookmark =
                          bookmarks[index].data() as Map<String, dynamic>;
                      final locationId = bookmark['locationId'] ?? '';

                      final locationData = locationsMap[locationId];

                      final name = (locationData != null && locationData['name'] != null)
                          ? locationData['name']
                          : (bookmark['name'] ?? 'بدون اسم');

                      final governorate = (locationData != null && locationData['governorate'] != null)
                          ? locationData['governorate']
                          : (bookmark['governorate'] ?? '');

                    
                      String imageUrl = '';
                      if (locationData != null &&
                          locationData['images'] != null &&
                          locationData['images'] is List &&
                          locationData['images'].isNotEmpty) {
                        imageUrl = locationData['images'][0];
                      } else if (bookmark['images'] != null &&
                          bookmark['images'] is List &&
                          bookmark['images'].isNotEmpty) {
                        imageUrl = bookmark['images'][0];
                      } else if (locationData != null &&
                          locationData['imageUrl'] != null) {
                        imageUrl = locationData['imageUrl'];
                      } else if (bookmark['imageUrl'] != null) {
                        imageUrl = bookmark['imageUrl'];
                      }

                      if (name == null && governorate == null && imageUrl == null) {
                        return const SizedBox();
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.location_on,
                                                size: 40),
                                  ),
                                )
                              : const Icon(Icons.location_on, size: 40),
                          title: Text(name),
                          subtitle: Text(governorate),
                          trailing: IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await bookmarks[index].reference.delete();
                            },
                          ),
                          onTap: () {
                            if (locationId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LocationDetailsPage(locationId: locationId),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    } catch (e) {
                      print('Error parsing bookmark at index $index: $e');
                      return const SizedBox();
                    }
                  },
                );
              },
            );
          }

          return const Center(
            child: Text('جارٍ تحميل المفضلة...'),
          );
        },
      ),
    );
  }
}
