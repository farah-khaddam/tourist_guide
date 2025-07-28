// login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourist_guide/home_page.dart';
import 'package:tourist_guide/register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  static GlobalKey<FormState> formkey = GlobalKey();

  LoginScreen({super.key});

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
            "تسجيل الدخول",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formkey,
            child: Column(
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == '' || value == null) {
                      return 'هذا الحقل مطلوب';
                    }
                    return null;
                  },
                  controller: email,
                  decoration: const InputDecoration(
                    focusColor: Colors.teal,
                    labelText: 'البريد الالكتروني',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  validator: (value) {
                    if (value == '' || value == null) {
                      return 'هذا الحقل مطلوب';
                    }
                    return null;
                  },
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة السر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      "ليس لديك حساب ؟",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(
                      width: 18,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ));
                      },
                      child: const Text(
                        "إنشاء حساب",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.teal,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                ElevatedButton(
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 12, horizontal: 40)),
                    backgroundColor: WidgetStatePropertyAll(Colors.teal),
                  ),
                  onPressed: () async {
                    try {
                      if (formkey.currentState!.validate()) {
                        UserCredential userCredential = await FirebaseAuth
                            .instance
                            .signInWithEmailAndPassword(
                          email: email.text,
                          password: password.text,
                        );
                        QuerySnapshot snapshot = await FirebaseFirestore
                            .instance
                            .collection('user')
                            .where('email', isEqualTo: email.text.trim())
                            .get();
                        if (snapshot.docs.isNotEmpty) {
                          final data = snapshot.docs.first.data()
                              as Map<String, dynamic>;
                          final isAdmin = data['isAdmin'] ?? false;
                          showSnackBar(context, "مرحبًا!");
                          await Future.delayed(
                              const Duration(milliseconds: 500));

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );

                        } else {
                          showSnackBar(context,
                              "لم يتم العثور على بيانات المستخدم في النظام.");
                        }
                      }
                    } catch (e) {
                      showSnackBar(
                          context, "فشل تسجيل الدخول: ${e.toString()}");
                      print('Failed to login : $e');
                    }
                  },
                  child: const Text(
                    'تسجيل دخول',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Center(child: Text(message)),
    backgroundColor: Colors.teal,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ));
}
