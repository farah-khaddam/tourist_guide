// login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool showPassword = false;

  String? loggedName;
  String? loggedPhoto;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      loggedName = user.displayName ?? user.email;
      loggedPhoto = user.photoURL;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = loggedName != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("الحساب"),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: !isLoggedIn
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "ليس لديك حساب؟",
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "البريد الإلكتروني",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: "كلمة المرور",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();
                          if (email.isEmpty || password.isEmpty) {
                            showSnackBar(
                              context,
                              "الرجاء إدخال البريد وكلمة المرور",
                            );
                            return;
                          }

                          try {
                            final userSnap = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(email)
                                .get();
                            if (userSnap.exists &&
                                userSnap.data()!['appPassword'] == password) {
                              setState(() {
                                loggedName = userSnap.data()!['name'];
                                loggedPhoto = userSnap.data()!['photo'];
                              });
                              showSnackBar(context, "تم تسجيل الدخول بنجاح!");
                            } else {
                              showSnackBar(
                                context,
                                "البريد أو كلمة المرور غير صحيحة",
                              );
                            }
                          } catch (e) {
                            showSnackBar(context, "فشل تسجيل الدخول: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text("تسجيل دخول"),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          try {
                            final googleUser = await GoogleSignIn().signIn();
                            if (googleUser == null) return;

                            final googleAuth = await googleUser.authentication;
                            final credential = GoogleAuthProvider.credential(
                              accessToken: googleAuth.accessToken,
                              idToken: googleAuth.idToken,
                            );

                            final userCredential = await _auth
                                .signInWithCredential(credential);

                            // حفظ البريد في Firestore إذا جديد
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userCredential.user!.email)
                                .set({
                                  'email': userCredential.user!.email,
                                  'name': userCredential.user!.displayName,
                                  'photo': userCredential.user!.photoURL,
                                }, SetOptions(merge: true));

                            setState(() {
                              loggedName =
                                  userCredential.user!.displayName ??
                                  userCredential.user!.email;
                              loggedPhoto = userCredential.user!.photoURL;
                            });

                            showSnackBar(
                              context,
                              "مرحبًا بك ${userCredential.user!.displayName}",
                            );
                          } catch (e) {
                            showSnackBar(context, "فشل تسجيل الدخول: $e");
                          }
                        },
                        child: const Text("إنشاء حساب باستخدام Google"),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: loggedPhoto != null
                            ? NetworkImage(loggedPhoto!)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "مرحبًا بك $loggedName",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
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
