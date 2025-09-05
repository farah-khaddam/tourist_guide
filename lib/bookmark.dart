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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final bookmarks = snapshot.data!.docs;
          if (bookmarks.isEmpty) {
            return const Center(child: Text('لا يوجد معالم محفوظة بعد.'));
          }

          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index].data() as Map<String, dynamic>;
              final locationId = bookmark['locationId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('location').doc(locationId).get(),
                builder: (context, locationSnap) {
                  if (!locationSnap.hasData) return const SizedBox();

                  if (!locationSnap.data!.exists) return const SizedBox();

                  final locationData = locationSnap.data!.data() as Map<String, dynamic>;
                  final name = locationData['name'] ?? 'بدون اسم';
                  final governorate = locationData['governorate'] ?? '';
                  final imageUrl = locationData['imageUrl'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.location_on, size: 40),
                      title: Text(name),
                      subtitle: Text(governorate),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await bookmarks[index].reference.delete();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationDetailsPage(locationId: locationId),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
