// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'home_page.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<Map<String, String>> slides = [
    {
      "image": "assets/images/v.png",
      "text": "هل تبحث عن المعالم السياحية في سوريا؟",
    },
    {
      "image": "assets/images/mm.png",
      "text": "هل تريد أن تعرف مكانها بسهولة؟",
    },
    {"image": "assets/images/c.png", "text": "من الجبال إلى البحر"},
    {"image": "assets/images/l.png", "text": "كل المعالم بين يديك بدليل واحد"},
  ];
int _currentIndex = 0;

  void _nextSlide() {
    if (_currentIndex < slides.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
     
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8C42),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
  
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Image.asset(
                slides[_currentIndex]["image"]!,
                key: ValueKey(_currentIndex),
                height: 220,
              ),
            ),
            const SizedBox(height: 30),

          
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DefaultTextStyle(
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  color: const Color(0xFFF5DEB3),
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                child: AnimatedTextKit(
                  key: ValueKey(_currentIndex), 
                  isRepeatingAnimation: false,
                  onFinished: _nextSlide,
                  animatedTexts: [
                    TypewriterAnimatedText(
                      slides[_currentIndex]["text"]!,
                      speed: const Duration(milliseconds: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
