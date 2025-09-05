// register_screen.dart
import 'package:flutter/material.dart';
import 'package:tourist_guide/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey();
  bool linkSent = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Colors.teal,
          centerTitle: true,
          title: const Text(
            "إنشاء حساب",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'البريد الالكتروني',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 40,
                      ),
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: linkSent
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            final email = emailController.text.trim();
                            final name = nameController.text.trim();

                            try {
                              await sendSignInLink(email, name);
                              setState(() {
                                linkSent = true;
                              });
                              showSnackBar(
                                context,
                                "تم إرسال رابط إنشاء الحساب إلى بريدك الإلكتروني",
                              );
                            } catch (e) {
                              showSnackBar(context, "فشل إرسال الرابط: $e");
                            }
                          },
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendSignInLink(String email, String name) async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://your-app.firebaseapp.com',
      handleCodeInApp: true,
      iOSBundleId: 'com.example.ios',
      androidPackageName: 'com.example.android',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );

    // حفظ اسم وبريد المستخدم مؤقتًا في Firestore
    await FirebaseFirestore.instance.collection('user').doc(email).set({
      'name': name,
      'email': email,
    }, SetOptions(merge: true));
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(child: Text(message)),
      backgroundColor: Colors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
