// admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:TRIPSY/testscreen.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bgColor = themeProvider.isDark ? Colors.black : Colors.white;
    final textColor = themeProvider.isDark ? Colors.white : Colors.teal;
    const buttonAddColor = Colors.teal;
    final buttonEditColor = themeProvider.isDark
        ? Colors.grey.shade800
        : Colors.grey.shade700;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text("لوحة تحكم الأدمن"),
          backgroundColor: buttonAddColor,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonAddColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddLandmarkScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_location),
                label: const Text(
                  "إضافة موقع سياحي",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonEditColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // لاحقاً: تعديل أو حذف مواقع سياحية
                },
                icon: const Icon(Icons.edit_location_alt),
                label: const Text(
                  "تعديل / حذف موقع",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
