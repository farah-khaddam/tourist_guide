// Login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';


class LogOrSign extends StatefulWidget {
  final VoidCallback? redirectPage; // <-- أضفنا هذا

  const LogOrSign({Key? key, this.redirectPage}) : super(key: key); // <-- عدّل الكونستركتور

  @override
  _LogOrSignState createState() => _LogOrSignState();
}


class _LogOrSignState extends State<LogOrSign> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

Future<void> _loginWithGoogle() async {
  try {
    setState(() => _isLoading = true);

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // المستخدم لغى العملية
      setState(() => _isLoading = false);
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);

    // (اختياري) إنشاء وثيقة للمستخدم في Firestore إذا ما كانت موجودة
    // حتى تقدر تجيب "name" لاحقاً للكومنتات
    try {
      final u = _auth.currentUser;
      if (u != null) {
        final docRef = FirebaseFirestore.instance.collection('user').doc(u.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'name': u.displayName ?? 'بدون اسم',
            'email': u.email,
            'isAdmin': false,
          });
        }
      }
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم تسجيل الدخول بحساب Google 🎉")),
    );

    // نفس منطق الإرجاع يلي عملتو بتسجيل الإيميل/كلمة السر
    if (widget.redirectPage != null) {
      widget.redirectPage!();
    } else {
      Navigator.pop(context, true);
    }
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("فشل تسجيل الدخول: ${e.message ?? e.code}")),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("فشل تسجيل الدخول: $e")),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}



  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تسجيل الدخول بنجاح 🎉")),
      );

      Navigator.pop(context, true);
      // استدعاء دالة إعادة التوجيه إذا موجودة
      //if (widget.redirectPage != null) {
       // widget.redirectPage!();
      //} else {
        //Navigator.pop(context);
        // توجيه افتراضي للصفحة الرئيسية
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      //} 
    
      

    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'المستخدم غير موجود';
      } else if (e.code == 'wrong-password') {
        message = 'كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح';
      } else {
        message = 'حدث خطأ، حاول مرة أخرى';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("أدخل بريدك الإلكتروني أولاً")),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطأ في إرسال الرابط")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final Color orangeColor =
        themeProvider.isDark ? themeProvider.orangeDark : themeProvider.orangeLight;
    final Color backgroundColor =
        themeProvider.isDark ? Colors.black : themeProvider.beigeLight;
    final Color fieldFillColor =
        themeProvider.isDark ? Colors.grey.shade900 : Colors.white;
    final Color textColor =
        themeProvider.isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("تسجيل الدخول"),
        backgroundColor: orangeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: "البريد الإلكتروني",
                    labelStyle: TextStyle(color: textColor),
                    filled: true,
                    fillColor: fieldFillColor,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orangeColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: "كلمة المرور",
                    labelStyle: TextStyle(color: textColor),
                    filled: true,
                    fillColor: fieldFillColor,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orangeColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: orangeColor)
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "تسجيل الدخول",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    "نسيت كلمة المرور؟",
                    style: TextStyle(color: orangeColor),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.grey),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  
                  child: Text(
                    "مستخدم جديد؟ أنشئ حساب",
                    style: TextStyle(color: orangeColor),
                  ),
                ),
                const SizedBox(height: 10),
                  Material(
                  color: Colors.transparent, // 👈 حتى ما يطلع خلفية
                  child: InkWell(
                    onTap: _loginWithGoogle,
                    child: ClipRRect(
                    borderRadius: BorderRadius.circular(20), // حواف دائرية حسب الرقم
                    child: Image.asset(
                      "assets/images/google.png",
                      height: 150, // ارتفاع الصورة
                      width: 150,  // عرض الصورة
                      fit: BoxFit.contain, // يحافظ على ملء الحاوية بدون تشويه
                    ),
                  ),
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

