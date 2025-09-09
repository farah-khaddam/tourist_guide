// home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'location_details_page.dart';
import 'settings_page.dart';
import 'map_screen.dart';
import 'package:TRIPSY/admin_dashboard.dart';
import 'theme_provider.dart';
import 'bookmark.dart';
import 'EventsPage.dart';
import 'notifications_screen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedGovernorate;
  String? selectedType;
  bool isAdmin = false;
  User? currentUser;
  int _selectedIndex = 0;
  String searchQuery = '';
  List<String> allLocations = [];

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

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    checkIfAdmin();
    fetchAllLocations();
  }

  Future<void> checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null && data['isAdmin'] == true) {
        setState(() {
          isAdmin = true;
        });
      }
    }
  }

  Future<void> fetchAllLocations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('location')
        .get();
    final names = snapshot.docs
        .map((doc) => (doc.data()['name'] ?? '').toString())
        .toList();
    setState(() {
      allLocations = names;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // الرئيسية
        setState(() {
          selectedGovernorate = null;
          selectedType = null;
          searchQuery = '';
        });
        break;
      case 1:
        _showSearchDialog();
        break;
      case 2:
        // أول ما يضغط على الخريطة، نظهر رسالة توضيحية 5 ثواني
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("يمكنك اختيار المسافة للمواقع القريبة من الاعلى"),

            duration: Duration(seconds: 5),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
        break;
      case 3: // الفعاليات
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventsPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
        break;
    }
  }

  void _showFilterChoiceDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bgColor = themeProvider.isDark
        ? const Color.fromARGB(255, 5, 5, 5)
        : const Color(0xFFFFF5E1);
    final btnColor = themeProvider.isDark
        ? themeProvider.orangeDark
        : Colors.orange.shade700;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("اختر نوع التصنيف", style: TextStyle(color: btnColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: btnColor),
              onPressed: () {
                Navigator.pop(context);
                _showFilterDialog(isGovernorate: true);
              },
              child: const Text("حسب المحافظة"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: btnColor),
              onPressed: () {
                Navigator.pop(context);
                _showFilterDialog(isGovernorate: false);
              },
              child: const Text("حسب نوع المعلم"),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog({required bool isGovernorate}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bgColor = themeProvider.isDark
        ? Colors.black
        : const Color(0xFFFFF5E1);
    final textColor = themeProvider.isDark ? Colors.white : Colors.orange;

    showModalBottomSheet(
      backgroundColor: bgColor,
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGovernorate ? "تصنيف حسب المحافظة" : "تصنيف حسب النوع",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: isGovernorate ? selectedGovernorate : selectedType,
              decoration: InputDecoration(
                labelText: isGovernorate ? 'المحافظة' : 'نوع المعلم',
                border: const OutlineInputBorder(),
              ),
              items: (isGovernorate ? governorates : types)
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: TextStyle(color: textColor)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  if (isGovernorate) {
                    selectedGovernorate = val;
                  } else {
                    selectedType = val;
                  }
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bgColor = themeProvider.isDark
        ? Colors.black
        : const Color(0xFFFFF5E1);
    final textColor = themeProvider.isDark ? Colors.white : Colors.orange;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("ابحث عن معلم", style: TextStyle(color: textColor)),
        content: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return allLocations.where(
              (name) => name.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          onSelected: (String selection) async {
            final snapshot = await FirebaseFirestore.instance
                .collection('location')
                .where('name', isEqualTo: selection)
                .get();
            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocationDetailsPage(locationId: doc.id),
                ),
              );
            }
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            controller.text = searchQuery;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "اكتب أي شيء...",
                hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                border: const OutlineInputBorder(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bgColor = themeProvider.isDark
        ? Colors.black
        : const Color(0xFFFFF5E1);
    final cardColor = themeProvider.isDark
        ? Colors.grey.shade900
        : const Color(0xFFFFF5E1);
    final textColor = themeProvider.isDark
        ? Colors.white
        : Colors.orange.shade700;
    final navBarColor = themeProvider.isDark
        ? Colors.grey.shade900
        : Colors.orange.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navBarColor,
        leading: IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterChoiceDialog,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            color: Colors.white,
          ),

          // 👈 استخدم StreamBuilder لتحديث أيقونة البوك مارك تلقائيًا
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) {
                return const SizedBox(); // لا تظهر الأيقونة إذا لم يسجل الدخول
              }
              return IconButton(
                icon: const Icon(Icons.bookmark),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookmarkPage()),
                  );
                },
                color: Colors.white,
              );
            },
          ),

          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) return const SizedBox();
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('user')
                    .doc(user.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null && data['isAdmin'] == true) {
                    return IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboard(),
                          ),
                        );
                      },
                      color: Colors.white,
                    );
                  }
                  return const SizedBox();
                },
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('location').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final locations = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final governorate = data['governorate'];
            final type = data['type'];
            final name = (data['name'] ?? '').toLowerCase();
            final query = searchQuery.toLowerCase();

            return (selectedGovernorate == null ||
                    selectedGovernorate == 'الكل' ||
                    governorate == selectedGovernorate) &&
                (selectedType == null ||
                    selectedType == 'الكل' ||
                    type == selectedType) &&
                (name.contains(query));
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 معالم بكل صف
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2 / 3,
            ),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final doc = locations[index];
              final data = doc.data() as Map<String, dynamic>;
              final List<String> images = List<String>.from(
                data['images'] ?? [],
              );
              final String firstImage = images.isNotEmpty ? images.first : '';

              final name = data['name'] ?? 'بدون اسم';

              return Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    print(doc.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationDetailsPage(locationId: doc.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: firstImage.isNotEmpty
                                ? Image.network(
                                    firstImage,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.location_on,
                                    size: 50,
                                    color: textColor,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['governorate'] ?? '',
                          style: TextStyle(color: textColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: navBarColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: themeProvider.isDark
            ? Colors.white70
            : Colors.orange.shade100,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "بحث"),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: "الخريطة",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "الفعاليات"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "الإعدادات",
          ),
        ],
      ),
    );
  }
}
