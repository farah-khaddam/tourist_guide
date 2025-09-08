import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EditSingleLandmarkScreen.dart';

class EditLandmarksScreen extends StatefulWidget {
  const EditLandmarksScreen({super.key});

  @override
  State<EditLandmarksScreen> createState() => _EditLandmarksScreenState();
}

class _EditLandmarksScreenState extends State<EditLandmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  Future<void> _deleteLandmark(String landmarkId, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من حذف هذا المعلم؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('location').doc(landmarkId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حذف المعلم بنجاح")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إدارة المعالم السياحية"),
          backgroundColor: Colors.teal,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن معلم',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchText = val.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('location').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final landmarks = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchText);
                    }).toList();

                    if (landmarks.isEmpty) return const Center(child: Text("لا توجد معالم حالياً."));

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: landmarks.length,
                      itemBuilder: (context, index) {
                        final doc = landmarks[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'بدون اسم';
                        final governorate = data['governorate'] ?? '-';
                        final type = data['type'] ?? '-';
                        final images = List<String>.from(data['images'] ?? []);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: SizedBox(
                              width: 60,
                              height: 60,
                              child: images.isNotEmpty
                                  ? Image.network(images.first, fit: BoxFit.cover)
                                  : const Icon(Icons.location_on, size: 60, color: Colors.grey),
                            ),
                            title: Text(name),
                            subtitle: Text('المحافظة: $governorate - التصنيف: $type'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditSingleLandmarkScreen(landmarkDoc: doc),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteLandmark(doc.id, context),
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
            ],
          ),
        ),
      ),
    );
  }
}
