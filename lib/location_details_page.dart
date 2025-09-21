// location_details_page.dart
// location_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Login.dart';
import 'bookmark.dart';

class LocationDetailsPage extends StatefulWidget {
  final String locationId;

  const LocationDetailsPage({required this.locationId, super.key});

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  int currentImageIndex = 0;
  late final PageController _pageController;
  bool isSaved = false;
  bool isAdmin = false;
  String? userId;
  final double cardRadius = 16;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      checkIfBookmarked();
      checkIfAdmin();
    }
  }

 
  Color get backgroundColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : const Color(0xFFFFF5E1);
  Color get cardColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2C)
      : Colors.white;
  Color get textColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : Colors.black;
  Color get primaryColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFB85C00)
      : const Color(0xFFFF9800);

  Future<void> checkIfAdmin() async {
    if (userId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .get();
    final data = doc.data();
    if (data != null && data['isAdmin'] == true) {
      setState(() {
        isAdmin = true;
      });
    }
  }

  Future<void> checkIfBookmarked() async {
    if (userId != null) {
      bool result = await isBookmarked(userId!, widget.locationId);
      setState(() {
        isSaved = result;
      });
    }
  }

  Future<bool> isBookmarked(String userId, String locationId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('locationId', isEqualTo: locationId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> addBookmark(String userId, String locationId) async {
    await FirebaseFirestore.instance.collection('bookmarks').add({
      'userId': userId,
      'locationId': locationId,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> removeBookmark(String userId, String locationId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('locationId', isEqualTo: locationId)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> submitRating(int rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('location')
        .doc(widget.locationId)
        .collection('ratings')
        .doc(user.uid)
        .set({
          'rating': rating,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مطلوب تسجيل الدخول'),
        content: const Text('يجب أن تكون مسجل دخول للقيام بهذه العملية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LogOrSign(
                    redirectPage: () {
                   
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        setState(() {
                          userId = user.uid;
                          checkIfBookmarked();
                          checkIfAdmin();
                        });
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أهلاً بك  لقد سجلت الدخول بنجاح.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            child: const Text('تسجيل دخول'),
          ),
        ],
      ),
    );
  }

  void onStarPressed(int rating) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog();
    } else {
      submitRating(rating).then((_) => setState(() {}));
    }
  }

  Future<void> submitComment(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    
    final userDoc = await FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? 'مستخدم مجهول';

    await FirebaseFirestore.instance.collection('comment').add({
      'userId': user.uid,
      'username': userName, 
      'locationId': widget.locationId,
      'text': text,
      'createdAt': Timestamp.now(),
    });

    _commentController.clear();
  }

  Widget _buildCommentBox() {
    final user = FirebaseAuth.instance.currentUser;
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                readOnly: user == null,
                onTap: () {
                  if (user == null) _showLoginDialog();
                },
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'أضف تعليقًا...',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (user != null)
              IconButton(
                icon: Icon(Icons.send, color: primaryColor),
                onPressed: () {
                  final text = _commentController.text.trim();
                  if (text.isNotEmpty) {
                    submitComment(text).then((_) => setState(() {}));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Stream<Map<String, dynamic>> ratingStatsStream() {
    return FirebaseFirestore.instance
        .collection('location')
        .doc(widget.locationId)
        .collection('ratings')
        .snapshots()
        .map((snapshot) {
          int total = 0, sum = 0;
          for (var doc in snapshot.docs) {
            final r = (doc.data()['rating'] ?? 0) as int;
            sum += r;
            total++;
          }
          final avg = total > 0 ? sum / total : 0.0;
          return {'average': avg, 'count': total};
        });
  }

  Widget myRatingRow() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Row(
        children: List.generate(
          5,
          (i) => IconButton(
            icon: const Icon(Icons.star_border, color: Colors.amber),
            onPressed: () => onStarPressed(i + 1),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('location')
          .doc(widget.locationId)
          .collection('ratings')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        int myRating = 0;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          myRating = (d['rating'] ?? 0) as int;
        }
        return Row(
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            return IconButton(
              icon: Icon(
                starIndex <= myRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () => onStarPressed(starIndex),
            );
          }),
        );
      },
    );
  }

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

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comment')
          .where('locationId', isEqualTo: widget.locationId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final comments = snapshot.data!.docs;

        bool showAll = false; 
        int displayCount = comments.length > 2 ? 2 : comments.length;

        return StatefulBuilder(
          builder: (context, setStateSB) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التعليقات (${comments.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              ...comments.take(showAll ? comments.length : displayCount).map((
                doc,
              ) {
                final data = doc.data() as Map<String, dynamic>;
                final commentText = data['text'] ?? '';
                final userName = data['username'] ?? 'مستخدم مجهول';
                final timestamp = data['createdAt'] as Timestamp?;
                final timeString = timestamp != null
                    ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
                    : '';

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeString,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                commentText,
                                style: TextStyle(color: textColor),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        if (userId == data['userId'] || isAdmin)
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('comment')
                                  .doc(doc.id)
                                  .delete();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (comments.length > 2)
                TextButton(
                  onPressed: () {
                    setStateSB(() {
                      showAll = !showAll;
                    });
                  },
                  child: Text(showAll ? "عرض أقل" : "عرض المزيد"),
                ),
              const SizedBox(height: 8),
              _buildCommentBox(), 
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('location')
          .doc(widget.locationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.data!.exists) {
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
            data['imageUrl'].toString().isNotEmpty)
          images = [data['imageUrl']];
        print(images);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              title: const Text('تفاصيل الموقع'),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            
              actions: [
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                   
                      _showLoginDialog();
                      return;
                    }

                    String message;
                    if (isSaved) {
                      await removeBookmark(user.uid, widget.locationId);
                      message = 'تمت الإزالة من قائمة المفضلة';
                    } else {
                      await addBookmark(user.uid, widget.locationId);
                      message = 'تمت الإضافة إلى قائمة المفضلة';
                    }

                    setState(() => isSaved = !isSaved);

                  
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (images.isNotEmpty) _buildImageCarousel(images),
                  const SizedBox(height: 16),
                  Card(
                    color: cardColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                governorate,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'تصنيف الموقع: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                data['type'] ?? 'غير محدد',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'الوصف:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'طبيعة الطريق:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['terrain'] ?? 'غير محددة',
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  StreamBuilder<Map<String, dynamic>>(
                    stream: ratingStatsStream(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final avg = snap.data!['average'] as double;
                      final count = snap.data!['count'] as int;
                      return Card(
                        color: cardColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(cardRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تقييم المستخدمين ($count تقييم)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              averageStars(avg),
                              Text(
                                "المتوسط: ${avg.toStringAsFixed(1)} / 5",
                                style: TextStyle(color: textColor),
                              ),
                              const SizedBox(height: 12),
                              myRatingRow(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCommentsList(),
                  const SizedBox(height: 16),
                  Card(
                    color: cardColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    child: SizedBox(
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cardRadius),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(latitude, longitude),
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.tourist_guide',
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
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return ImageCarousel(
      images: images,
      primaryColor: primaryColor,
      cardRadius: cardRadius,
    );
  }
}


class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final Color primaryColor;
  final double cardRadius;
  const ImageCarousel({
    required this.images,
    required this.primaryColor,
    required this.cardRadius,
    super.key,
  });

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(widget.cardRadius),
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  color: isDark ? Colors.black.withOpacity(0.2) : null,
                  colorBlendMode: isDark ? BlendMode.darken : null,
                ),
              );
            },
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
                color: currentImageIndex == index
                    ? widget.primaryColor
                    : Colors.grey,
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
              child: Image.network(widget.images[index], fit: BoxFit.contain),
            );
          },
        ),
      ),
    );
  }
}
