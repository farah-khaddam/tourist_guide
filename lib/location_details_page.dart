// location_details_page.dart
 // location_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourist_guide/Login.dart';
import 'package:tourist_guide/EditLandmarkScreen.dart';

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

  // ألوان حسب الوضع
  Color get backgroundColor =>
      Theme.of(context).brightness == Brightness.dark ? Colors.black : Color(0xFFFFF5E1);
  Color get cardColor =>
      Theme.of(context).brightness == Brightness.dark ? Color(0xFF2C2C2C) : Colors.white;
  Color get textColor =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
  Color get primaryColor =>
      Theme.of(context).brightness == Brightness.dark ? Color(0xFFB85C00) : Color(0xFFFF9800);

  Future<void> checkIfAdmin() async {
    if (userId == null) return;
    final doc = await FirebaseFirestore.instance.collection('user').doc(userId).get();
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
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LogOrSign(
                    redirectPage: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LocationDetailsPage(locationId: widget.locationId),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أهلاً بك! 😊 لقد سجلت الدخول بنجاح.'),
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
    await FirebaseFirestore.instance
        .collection('location')
        .doc(widget.locationId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'comment': text,
      'timestamp': Timestamp.now(),
    });
    _commentController.clear();
  }

  Widget _buildCommentBox() {
    final user = FirebaseAuth.instance.currentUser;
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
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
                  if (text.isNotEmpty) submitComment(text).then((_) => setState(() {}));
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
            icon: Icon(Icons.star_border, color: Colors.amber),
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
          .collection('location')
          .doc(widget.locationId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final comments = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التعليقات (${comments.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            ...comments.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final commentText = data['comment'] ?? '';
              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(commentText, style: TextStyle(color: textColor)),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('location').doc(widget.locationId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists) return const Center(child: Text('لم يتم العثور على بيانات.'));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'بدون اسم';
        final description = data['description'] ?? 'لا يوجد وصف';
        final governorate = data['governorate'] ?? 'غير محددة';
        final latitude = (data['latitude'] ?? 0.0).toDouble();
        final longitude = (data['longitude'] ?? 0.0).toDouble();

        List<String> images = [];
        if (data['images'] != null) images = List<String>.from(data['images']);
        else if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
          images = [data['imageUrl']];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              title: const Text('تفاصيل الموقع'),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
                  onPressed: () async {
                    if (userId == null) return;
                    if (isSaved)
                      await removeBookmark(userId!, widget.locationId);
                    else
                      await addBookmark(userId!, widget.locationId);
                    setState(() => isSaved = !isSaved);
                  },
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditLandmarkScreen(landmark: snapshot.data!),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(governorate, style: TextStyle(fontSize: 16, color: textColor)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('الوصف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 6),
                          Text(description, style: TextStyle(fontSize: 16, color: textColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<Map<String, dynamic>>(
                    stream: ratingStatsStream(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const CircularProgressIndicator();
                      final avg = snap.data!['average'] as double;
                      final count = snap.data!['count'] as int;
                      return Card(
                        color: cardColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('تقييم المستخدمين ($count تقييم)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              averageStars(avg),
                              Text("المتوسط: ${avg.toStringAsFixed(1)} / 5", style: TextStyle(color: textColor)),
                              const SizedBox(height: 12),
                              myRatingRow(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCommentBox(),
                  const SizedBox(height: 16),
                  _buildCommentsList(),
                  const SizedBox(height: 16),
                  Card(
                    color: cardColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
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
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.tourist_guide',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(latitude, longitude),
                                  width: 80,
                                  height: 80,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
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
    return ImageCarousel(images: images, primaryColor: primaryColor, cardRadius: cardRadius);
  }
}

// Carousel
class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final Color primaryColor;
  final double cardRadius;
  const ImageCarousel({required this.images, required this.primaryColor, required this.cardRadius, super.key});

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
                color: currentImageIndex == index ? widget.primaryColor : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Full screen view
class FullImageView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullImageView({super.key, required this.images, required this.initialIndex});

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
              ),
            );
          },
        ),
      ),
    );
  }
}
