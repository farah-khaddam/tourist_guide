// register_screen.dart
// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'package:tourist_guide/home_page.dart';
import 'package:tourist_guide/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  static GlobalKey<FormState> formkey = GlobalKey();
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
              key: formkey,
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
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
                    controller: emailController,
                    decoration: const InputDecoration(
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
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة السر',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                      ),
                      backgroundColor: WidgetStatePropertyAll(Colors.teal),
                    ),
                    onPressed: () async {
                      try {
                        if (formkey.currentState!.validate()) {
                          String email = emailController.text;
                          String password = passwordController.text;
                          String name = nameController.text;

                          ///TODO ربط انشاء حساب
                          UserCredential userCredential = await FirebaseAuth
                              .instance
                              .createUserWithEmailAndPassword(
                                email: email,
                                password: password,
                              );

                          await FirebaseFirestore.instance
                              .collection('user')
                              .doc(userCredential.user!.uid)
                              .set({
                                'email': email,
                                'name': name,
                                'isAdmin': false,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                          showSnackBar(context, "Welcome!");
                          Future.delayed(const Duration(milliseconds: 500));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Failed to login : $e');
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
}
