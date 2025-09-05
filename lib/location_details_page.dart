// location_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourist_guide/login_screen.dart';

class LocationDetailsPage extends StatefulWidget {
  final String locationId;

  const LocationDetailsPage({required this.locationId, super.key});

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  int currentImageIndex = 0;
  late final PageController _pageController;
  final TextEditingController _commentController = TextEditingController();
  bool isSaved = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      checkIfBookmarked();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void checkIfBookmarked() async {
    if (userId != null) {
      bool result = await isBookmarked(userId!, widget.locationId);
      setState(() {
        isSaved = result;
      });
    }
  }

  Future<bool> isBookmarked(String userId, String locationId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookmark')
        .where('userId', isEqualTo: userId)
        .where('locationId', isEqualTo: locationId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> addBookmark(String userId, String locationId) async {
    await FirebaseFirestore.instance.collection('bookmark').add({
      'userId': userId,
      'locationId': locationId,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> removeBookmark(String userId, String locationId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookmark')
        .where('userId', isEqualTo: userId)
        .where('locationId', isEqualTo: locationId)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> addComment(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // لو المستخدم مو مسجل دخول نعمل Dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("مطلوب تسجيل الدخول"),
          content: const Text("يجب تسجيل الدخول لكتابة تعليق."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: const Text("تسجيل دخول"),
            ),
          ],
        ),
      );
      return;
    }

    print("DEBUG: user.displayName = ${user.displayName}");
    print("DEBUG: user.email = ${user.email}");
    final commentName = user.displayName ?? user.email ?? "مستخدم";
    print("DEBUG: Final comment name = $commentName");
    await FirebaseFirestore.instance.collection('comment').add({
      'userId': user.uid,
      'name': commentName,
      'locationId': widget.locationId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  Stream<QuerySnapshot> commentsStream() {
    return FirebaseFirestore.instance
        .collection('comment')
        .where('locationId', isEqualTo: widget.locationId)
        .orderBy('createdAt', descending: true)
        .snapshots();
        
  }

  Future<void> submitRating(int rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ratingDoc = FirebaseFirestore.instance
        .collection('ratings')
        .doc('${widget.locationId}_${user.uid}');

    await ratingDoc.set({
      'locationId': widget.locationId,
      'userId': user.uid,
      'rating': rating.toDouble(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void onStarPressed(int rating) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('مطلوب تسجيل الدخول'),
          content: const Text('يجب أن تكون مسجل دخول لتقييم هذا المعلم.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => LoginScreen()));
              },
              child: const Text('تسجيل دخول'),
            ),
          ],
        ),
      );
    } else {
      submitRating(rating).then((_) {
        setState(() {}); // إعادة بناء واجهة المستخدم بعد التقييم
      });
    }
  }

  /// إحصائيات التقييمات بشكل Stream لتتحدث لحظياً
  Stream<Map<String, dynamic>> ratingStatsStream() {
    return FirebaseFirestore.instance
        .collection('ratings')
        .where('locationId', isEqualTo: widget.locationId)
        .snapshots()
        .map((snapshot) {
          double sum = 0;
          int total = snapshot.docs.length;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final r = (data['rating'] ?? 0).toDouble();
            sum += r;
          }

          final avg = total > 0 ? sum / total : 0.0;
          return {'average': avg};
        });
  }

  /// عرض تقييم المستخدم الحالي (نجوم ملونة)
  Widget myRatingRow() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Row(
        children: List.generate(
          5,
          (i) => IconButton(
            icon: const Icon(Icons.star_border, color: Colors.teal),
            onPressed: () => onStarPressed(i + 1),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ratings')
          .doc('${widget.locationId}_$uid')
          .snapshots(),
      builder: (context, snap) {
        int myRating = 0;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          myRating = ((d['rating'] ?? 0).toDouble()).round();
        }
        return Row(
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            return IconButton(
              icon: Icon(
                starIndex <= myRating ? Icons.star : Icons.star_border,
                color: Colors.teal,
              ),
              onPressed: () => onStarPressed(starIndex),
            );
          }),
        );
      },
    );
  }

  /// ودجت لعرض نجوم المتوسط الكلي
  Widget averageStars(double avg) {
    return Row(
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        return Icon(
          starIndex <= avg.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الموقع'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () async {
              if (userId == null) return;

              if (isSaved) {
                await removeBookmark(userId!, widget.locationId);
              } else {
                await addBookmark(userId!, widget.locationId);
              }

              setState(() {
                isSaved = !isSaved;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('location')
            .doc(widget.locationId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('لم يتم العثور على بيانات.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'بدون اسم';
          final description = data['description'] ?? 'لا يوجد وصف';
          final governorate = data['governorate'] ?? 'غير محددة';
          final latitude = (data['latitude'] ?? 0.0).toDouble();
          final longitude = (data['longitude'] ?? 0.0).toDouble();

          List<String> images = [];
          if (data['images'] != null) {
            images = List<String>.from(data['images']);
          } else if (data['imageUrl'] != null &&
              data['imageUrl'].toString().isNotEmpty) {
            images = [data['imageUrl']];
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // عرض الصور إن وجدت
                    ...images.isNotEmpty ? [ImageCarousel(images: images)] : [],
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  governorate,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'الوصف:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // StreamBuilder لإحصائيات التقييمات - المتوسط فقط
                    StreamBuilder<Map<String, dynamic>>(
                      stream: ratingStatsStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final stats = snapshot.data!;
                        final avg = stats['average'] as double;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "تقييم المستخدمين:",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            averageStars(avg),
                            Text("المتوسط: ${avg.toStringAsFixed(1)} / 5"),
                            const SizedBox(height: 8),
                            const Text(
                              "قيّم هذا المعلم:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            myRatingRow(),
                            const Divider(),
                          ],
                        );
                      },
                    ),

                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "التعليقات:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // إدخال تعليق
                    if (FirebaseAuth.instance.currentUser != null)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: "أضف تعليقك...",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.teal),
                            onPressed: () {
                              if (_commentController.text.trim().isNotEmpty) {
                                addComment(_commentController.text.trim());
                              }
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // عرض التعليقات
                    StreamBuilder<QuerySnapshot>(
                      stream: commentsStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Text("لا يوجد تعليقات بعد.");
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final c =
                                docs[index].data() as Map<String, dynamic>;
                            final text = c['text'] ?? "";
                            final name = c['name'] ?? "مجهول";

                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(text),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(latitude, longitude),
                              initialZoom: 13.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.tourist_guide',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(latitude, longitude),
                                    width: 80,
                                    height: 80,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Carousel وصور كاملة
class ImageCarousel extends StatefulWidget {
  final List<String> images;
  const ImageCarousel({required this.images, super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int currentImageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FullImageView(
                            images: widget.images,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image));
                        },
                      ),
                    ),
                  );
                },
              ),
              if (widget.images.length > 1 && currentImageIndex > 0)
                Positioned(
                  left: 8,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.teal,
                      size: 30,
                    ),
                    onPressed: () {
                      if (currentImageIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              if (widget.images.length > 1 &&
                  currentImageIndex < widget.images.length - 1)
                Positioned(
                  right: 8,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.teal,
                      size: 30,
                    ),
                    onPressed: () {
                      if (currentImageIndex < widget.images.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentImageIndex == index ? 12 : 8,
              height: currentImageIndex == index ? 12 : 8,
              decoration: BoxDecoration(
                color: currentImageIndex == index ? Colors.teal : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class FullImageView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullImageView({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<FullImageView> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${currentIndex + 1} / ${widget.images.length}'),
      ),
      body: Center(
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.white);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
