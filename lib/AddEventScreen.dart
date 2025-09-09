// AddEventScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // استيراد البروفايدر

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String description = '';
  DateTime? startDate;
  DateTime? endDate;
  String contactNumber = '';
  String imageUrl = '';
  List<String> selectedLocations = [];

  List<QueryDocumentSnapshot> allLocations = [];
  List<QueryDocumentSnapshot> filteredLocations = [];
  String locationSearch = '';

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('location').get();
    setState(() {
      allLocations = snapshot.docs;
      filteredLocations = allLocations;
    });
  }

  Future<void> _addEvent() async {
    if (_formKey.currentState!.validate() &&
        startDate != null &&
        endDate != null) {
      await FirebaseFirestore.instance.collection('event').add({
        'name': name,
        'description': description,
        'startDate': Timestamp.fromDate(startDate!),
        'endDate': Timestamp.fromDate(endDate!),
        'contactNumber': contactNumber,
        'imageUrl': imageUrl,
        'locationIds': selectedLocations,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إضافة الفعالية بنجاح!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("الرجاء ملء جميع الحقول واختيار التواريخ.")),
      );
    }
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => endDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context); // الحصول على الثيم الحالي
    final isDark = theme.isDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إضافة فعالية"),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "اسم الفعالية",
                    filled: true,
                    fillColor: Theme.of(context)
                        .inputDecorationTheme
                        .fillColor, // يعتمد على الثيم
                    border: Theme.of(context).inputDecorationTheme.border,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "مطلوب" : null,
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "الوصف",
                    filled: true,
                    fillColor: Theme.of(context)
                        .inputDecorationTheme
                        .fillColor,
                    border: Theme.of(context).inputDecorationTheme.border,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "مطلوب" : null,
                  onChanged: (val) => description = val,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "رابط الصورة",
                    filled: true,
                    fillColor: Theme.of(context)
                        .inputDecorationTheme
                        .fillColor,
                    border: Theme.of(context).inputDecorationTheme.border,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "مطلوب" : null,
                  onChanged: (val) => imageUrl = val,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickStartDate,
                        child: Text(startDate == null
                            ? "تاريخ البداية"
                            : startDate!
                                .toLocal()
                                .toString()
                                .split(' ')[0]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).elevatedButtonTheme.style
                                  ?.backgroundColor
                                  ?.resolve({}) ??
                                  Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickEndDate,
                        child: Text(endDate == null
                            ? "تاريخ النهاية"
                            : endDate!.toLocal().toString().split(' ')[0]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).elevatedButtonTheme.style
                                  ?.backgroundColor
                                  ?.resolve({}) ??
                                  Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "رقم للتواصل",
                    filled: true,
                    fillColor:
                        Theme.of(context).inputDecorationTheme.fillColor,
                    border: Theme.of(context).inputDecorationTheme.border,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "مطلوب" : null,
                  onChanged: (val) => contactNumber = val,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                Text("اختر الأماكن السياحية للفعالية",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: "ابحث عن مكان...",
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    border: Theme.of(context).inputDecorationTheme.border,
                  ),
                  onChanged: (val) {
                    setState(() {
                      locationSearch = val;
                      filteredLocations = allLocations.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['name'] ?? '')
                            .toLowerCase()
                            .contains(val.toLowerCase());
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView(
                    children: (locationSearch.isEmpty
                            ? allLocations
                            : filteredLocations)
                        .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final locName = data['name'] ?? 'بدون اسم';
                      final locId = doc.id;
                      return CheckboxListTile(
                        title: Text(locName),
                        value: selectedLocations.contains(locId),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedLocations.add(locId);
                            } else {
                              selectedLocations.remove(locId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).elevatedButtonTheme.style
                                ?.backgroundColor
                                ?.resolve({}) ??
                            Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("إضافة الفعالية"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
