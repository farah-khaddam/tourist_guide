// EditEventScreen.dart
import 'package:TRIPSY/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> existingData;

  const EditEventScreen({
    super.key,
    required this.eventId,
    required this.existingData,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late String description;
  DateTime? startDate;
  DateTime? endDate;
  late String contactNumber;
  late String imageUrl; // 🔹 حقل رابط الصورة
  List<String> selectedLocations = [];

  List<QueryDocumentSnapshot> allLocations = [];
  List<QueryDocumentSnapshot> filteredLocations = [];
  String locationSearch = '';

  @override
  void initState() {
    super.initState();
    fetchLocations();

    final data = widget.existingData;
    name = data['name'] ?? '';
    description = data['description'] ?? '';
    contactNumber = data['contactNumber'] ?? '';
    imageUrl = data['imageUrl'] ?? ''; // 🔹 تهيئة رابط الصورة

    // التحقق من التواريخ
    if (data.containsKey('startDate') && data['startDate'] != null) {
      if (data['startDate'] is Timestamp) startDate = (data['startDate'] as Timestamp).toDate();
      else if (data['startDate'] is DateTime) startDate = data['startDate'];
    }

    if (data.containsKey('endDate') && data['endDate'] != null) {
      if (data['endDate'] is Timestamp) endDate = (data['endDate'] as Timestamp).toDate();
      else if (data['endDate'] is DateTime) endDate = data['endDate'];
    }

    selectedLocations = List<String>.from(data['locationIds'] ?? []);
  }

  Future<void> fetchLocations() async {
    final snapshot = await FirebaseFirestore.instance.collection('location').get();
    setState(() {
      allLocations = snapshot.docs;
      filteredLocations = allLocations;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? startDate ?? DateTime.now() : endDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) startDate = picked;
        else endDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && startDate != null && endDate != null) {
      final updatedData = {
        'name': name,
        'description': description,
        'startDate': Timestamp.fromDate(startDate!),
        'endDate': Timestamp.fromDate(endDate!),
        'contactNumber': contactNumber,
        'locationIds': selectedLocations,
        'imageUrl': imageUrl, // 🔹 حفظ رابط الصورة
      };

      await FirebaseFirestore.instance
          .collection('event')
          .doc(widget.eventId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تعديل الفعالية بنجاح!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء ملء جميع الحقول واختيار التواريخ.")),
      );
    }
  }

  Future<void> _deleteEvent() async {
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
      await FirebaseFirestore.instance.collection('event').doc(widget.eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حذف الفعالية بنجاح")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تعديل الفعالية"),
          backgroundColor: AppTheme.orangeLight,
          actions: [
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteEvent),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: "اسم الفعالية"),
                  validator: (val) => val == null || val.isEmpty ? "مطلوب" : null,
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: "الوصف"),
                  validator: (val) => val == null || val.isEmpty ? "مطلوب" : null,
                  onChanged: (val) => description = val,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                // 🔹 حقل رابط الصورة فقط
                TextFormField(
                  initialValue: imageUrl,
                  decoration: const InputDecoration(labelText: "رابط الصورة"),
                  validator: (val) => val == null || val.isEmpty ? "مطلوب" : null,
                  onChanged: (val) => imageUrl = val,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _pickDate(isStart: true),
                        child: Text(startDate != null
                            ? startDate!.toLocal().toString().split(' ')[0]
                            : "تاريخ البداية"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _pickDate(isStart: false),
                        child: Text(endDate != null
                            ? endDate!.toLocal().toString().split(' ')[0]
                            : "تاريخ النهاية"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: contactNumber,
                  decoration: const InputDecoration(labelText: "رقم للتواصل"),
                  validator: (val) => val == null || val.isEmpty ? "مطلوب" : null,
                  onChanged: (val) => contactNumber = val,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                const Text("اختر الأماكن السياحية للفعالية",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "ابحث عن مكان...",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      locationSearch = val;
                      filteredLocations = allLocations
                          .where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return (data['name'] ?? '')
                                .toLowerCase()
                                .contains(val.toLowerCase());
                          })
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView(
                    children: (locationSearch.isEmpty ? allLocations : filteredLocations)
                        .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final locName = data['name'] ?? 'بدون اسم';
                      final locId = doc.id;
                      return CheckboxListTile(
                        title: Text(locName),
                        value: selectedLocations.contains(locId),
                        onChanged: (val) {
                          setState(() {
                            if (val == true)
                              selectedLocations.add(locId);
                            else
                              selectedLocations.remove(locId);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orangeLight,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("حفظ التعديلات"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
