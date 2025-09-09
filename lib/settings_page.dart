// settings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Login.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedLanguage = "العربية";
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final Color orangeColor = themeProvider.isDark
        ? themeProvider.orangeDark
        : themeProvider.orangeLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text("الإعدادات"),
        backgroundColor: orangeColor,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: ListView(
        children: [
          if (currentUser == null)
            ListTile(
              leading: Icon(Icons.login, color: orangeColor),
              title: const Text("تسجيل دخول / إنشاء حساب"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogOrSign()),
                ).then((_) {
                  setState(() {
                    currentUser = FirebaseAuth.instance.currentUser;
                  });
                });
              },
            ),
          SwitchListTile(
            title: const Text("الوضع الليلي"),
            secondary: Icon(Icons.dark_mode, color: orangeColor),
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          ListTile(
            leading: Icon(Icons.language, color: orangeColor),
            title: const Text("اللغة"),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              items: ["العربية", "English"].map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedLanguage = val);
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: orangeColor),
            title: const Text("المساعدة"),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("صفحة المساعدة قريباً...")),
            ),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: orangeColor),
            title: const Text("حول التطبيق"),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: "Tourist Guide",
              applicationVersion: "1.0.0",
              applicationLegalese: "© 2025",
            ),
          ),
          if (currentUser != null)
            ListTile(
              leading: Icon(Icons.logout, color: orangeColor),

              title: const Text("تسجيل الخروج"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                setState(() {
                  currentUser = null;
                });
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
