// home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'location_details_page.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'testscreen.dart'; // استيراد شاشة إضافة معلم

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedGovernorate;
  String? selectedType;
  double? selectedRadius;
  bool isGovernorateExpanded = false;

  final List<String> governorates = [
    'الكل',
    'دمشق',
    'حلب',
    'اللاذقية',
    'طرطوس',
    'حمص',
    'حماة',
    'درعا',
    'السويداء',
    'دير الزور',
    'ريف دمشق',
    'الرقة',
    'الحسكة',
    'القنيطرة',
    'ادلب',
  ];

  final List<String> types = ['الكل', 'تاريخي', 'طبيعي', 'ثقافي', 'ديني'];

  final List<Map<String, dynamic>> radiusOptions = [
    {'label': '5 كم', 'value': 5.0},
    {'label': '10 كم', 'value': 10.0},
    {'label': '20 كم', 'value': 20.0},
  ];

  Future<void> _openMapWithRadius(double radiusKm) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MapScreen(initialRadius: radiusKm)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("يرجى السماح باستخدام الموقع لعرض الخريطة.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المواقع السياحية'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddLandmarkScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => LoginScreen())),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'نوع المعلم',
                      border: OutlineInputBorder(),
                    ),
                    items: types
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedType = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: selectedRadius,
                    decoration: const InputDecoration(
                      labelText: 'المواقع القريبة',
                      border: OutlineInputBorder(),
                    ),
                    items: radiusOptions.map((option) {
                      return DropdownMenuItem<double>(
                        value: option['value'],
                        child: Text(option['label']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedRadius = val);
                        _openMapWithRadius(val);
                      }
                    },
                    hint: const Text('اختر المسافة'),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => isGovernorateExpanded = !isGovernorateExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(12),
                color: Colors.teal.withOpacity(0.05),
              ),
              child: isGovernorateExpanded
                  ? Wrap(
                      spacing: 8,
                      children: governorates.map((g) {
                        final selected = selectedGovernorate == g;
                        return ChoiceChip(
                          label: Text(g),
                          selected: selected,
                          selectedColor: Colors.teal,
                          labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.teal),
                          onSelected: (_) {
                            setState(() {
                              selectedGovernorate = g;
                              isGovernorateExpanded = false;
                            });
                          },
                        );
                      }).toList(),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_city, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          selectedGovernorate ?? 'اختر المحافظة',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.teal),
                      ],
                    ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('location').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                final locations = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final governorate = data['governorate'];
                  final type = data['type'];
                  return (selectedGovernorate == null ||
                          selectedGovernorate == 'الكل' ||
                          governorate == selectedGovernorate) &&
                      (selectedType == null ||
                          selectedType == 'الكل' ||
                          type == selectedType);
                }).toList();

                return ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final doc = locations[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['ImageUrl'] ?? '';
                    final name = data['name'] ?? 'بدون اسم';

                    return ListTile(
                      leading: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                              width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.location_on,
                              size: 40, color: Colors.teal),
                      title: Text(name,
                          style: const TextStyle(
                              color: Colors.teal, fontWeight: FontWeight.bold)),
                      subtitle: Text(data['governorate'] ?? ''),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                LocationDetailsPage(locationId: doc.id)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
