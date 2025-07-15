import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_details_page.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // إشعارات تجريبية
  final List<Map<String, String>> notifications = [
    {
      'title': 'تم إضافة موقع جديد',
      'body': 'تمت إضافة موقع "قلعة صلاح الدين".',
      'time': 'منذ دقيقة'
    },
    {
      'title': 'تحديث بيانات',
      'body': 'تم تحديث بيانات موقع "سد بلوران".',
      'time': 'منذ 10 دقائق'
    },
    {
      'title': 'عرض خاص',
      'body': 'احصل على خصم 20% عند زيارة "المتحف الوطني".',
      'time': 'اليوم'
    },
  ];

  // متغيرات القوائم المنسدلة
  String? selectedGovernorate;
  String? selectedNearby;
  String? selectedType;
  bool isGovernorateExpanded = false;

  ///TODO معالجة المحافظات والابعاد ونوع المعلَم السياحي
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
    'الرقة',
    'الحسكة',
  ];
  final List<String> nearbyOptions = [
    'الكل',
    '5 كم',
    '10 كم',
    '20 كم',
  ];
  final List<String> types = [
    'الكل',
    'تاريخي',
    'طبيعي',
    'ثقافي',
    'ديني',
  ];

  void _showNotificationsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'الإشعارات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: notifications.isEmpty
                      ? const Center(child: Text('لا توجد إشعارات حالياً.'))
                      : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            ///TODO معالجة الاشعارات
                            final notif = notifications[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: const Icon(Icons.notifications,
                                    color: Colors.teal),
                                title: Text(
                                  notif['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(notif['body'] ?? ''),
                                trailing: Text(
                                  notif['time'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:
                      const Text('إغلاق', style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'المواقع السياحية',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
            ),
            tooltip: 'الإشعارات',
            onPressed: () {
              _showNotificationsPopup(context);
            },
          ),

          ///TODO تحقق اذا المستخدم مسجل دخول
          ///عرض الايقونة بناء على النتيجة
          IconButton(
            icon: const Icon(
              Icons.login,
              // color: Colors.white,
            ),
            tooltip: 'تسجيل دخول',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('location').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد مواقع حالياً.'));
          }

          final locations = snapshot.data!.docs;

          return Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        borderRadius: BorderRadius.circular(24),
                        value: selectedNearby,
                        decoration: const InputDecoration(
                          labelText: 'المواقع القريبة',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.teal, width: 2),
                          ),
                          focusColor: Colors.teal,
                        ),
                        items: nearbyOptions
                            .map((n) => DropdownMenuItem(
                                  value: n,
                                  child: Text(n),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            ///TODO تم اختيار مسافة لعرض مواقع قريبة
                            selectedNearby = val;
                          });
                        },
                        hint: const Text('المسافة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // نوع المعلم
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        borderRadius: BorderRadius.circular(24),
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'نوع المعلم',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.teal, width: 2),
                          ),
                          focusColor: Colors.teal,
                        ),
                        items: types
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            ///TODO تم اختيار نوع المعلم
                            selectedType = val;
                          });
                        },
                        hint: const Text('نوع المعلم'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Colors.teal,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isGovernorateExpanded = !isGovernorateExpanded;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: isGovernorateExpanded ? 220 : 48,
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.teal, width: 1.5),
                    boxShadow: isGovernorateExpanded
                        ? [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: isGovernorateExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'اختر المحافظة',
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: governorates.map((g) {
                                    final isSelected = selectedGovernorate == g;
                                    return SizedBox(
                                      width: 100,
                                      child: ChoiceChip(
                                        label: Text(g,
                                            overflow: TextOverflow.ellipsis),
                                        selected: isSelected,
                                        selectedColor: Colors.teal,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.teal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        backgroundColor: Colors.white,
                                        showCheckmark: false,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: isSelected
                                                ? Colors.teal
                                                : Colors.teal.shade200,
                                          ),
                                        ),
                                        onSelected: (_) {
                                          setState(() {
                                            selectedGovernorate = g;
                                            isGovernorateExpanded = false;

                                            ///TODO تم اختيار المحافظة
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_city,
                                color: Colors.teal.shade400),
                            const SizedBox(width: 8),
                            Text(
                              selectedGovernorate != null
                                  ? 'المحافظة: $selectedGovernorate'
                                  : 'اختر المحافظة',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isGovernorateExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                ),
              ),
              const Divider(
                color: Colors.teal,
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final doc = locations[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final imageUrl = data['ImageUrl'] ?? '';
                    final name = data['name'] ?? 'بدون اسم';

                    return ListTile(
                      leading: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.location_on,
                              color: Colors.teal, size: 40),
                      title: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LocationDetailsPage(locationId: doc.id),
                            ),
                          );
                        },
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      subtitle: Text(data['governorate'] ?? 'غير محددة'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
