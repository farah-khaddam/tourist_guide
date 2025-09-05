// map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_details_page.dart';

class MapScreen extends StatefulWidget {
  final LatLng? oldPoint;
  final bool justForShow;

  const MapScreen({
    super.key,
    this.oldPoint,
    this.justForShow = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  Position? userLocation;
  List<Marker> nearbyMarkers = [];
  LatLng? _pickedLocation;
  double zoom = 13.0;
  double selectedRadius = 5; // القيمة الافتراضية 5 كم

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // التحقق من خدمة الموقع
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى تفعيل خدمة الموقع")));
      return;
    }

    // التحقق من الإذن
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم رفض إذن الموقع")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "تم رفض إذن الموقع بشكل دائم. يرجى تمكينه من إعدادات الهاتف")));
      return;
    }

    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    setState(() => userLocation = pos);
    _loadNearbyLocations();
  }

  Future<void> _loadNearbyLocations() async {
    if (userLocation == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('location').get();
    final docs = snapshot.docs;
    const Distance distance = Distance();

    // تصفية المعالم حسب المسافة
    final filtered = docs.where((doc) {
      final data = doc.data();
      final lat = data['latitude'];
      final lng = data['longitude'];

      if (lat == null || lng == null) return false;

      final d = distance.as(
        LengthUnit.Kilometer,
        LatLng(userLocation!.latitude, userLocation!.longitude),
        LatLng(lat, lng),
      );

      return d <= selectedRadius;
    }).toList();

    // إنشاء Marker لكل موقع قريب
    final markers = filtered.map((doc) {
      final data = doc.data();
      final List<dynamic> images = data['imageUrls'] ?? []; // صور المعلم

      return Marker(
        width: 50,
        height: 50,
        point: LatLng(data['latitude'], data['longitude']),
        child: GestureDetector(
          onTap: () {
            // عند الضغط على Marker
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(data['name'] ?? 'موقع'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // عرض صور المعلم
                    if (images.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                images[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),

                    // متوسط التقييم
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 5),
                        Text(
                          (data['averageRating'] ?? 0).toStringAsFixed(1),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // زر التفاصيل
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // إغلاق الـ Dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LocationDetailsPage(locationId: doc.id),
                          ),
                        );
                      },
                      child: const Text("عرض التفاصيل"),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Icon(Icons.location_on, size: 40, color: Color.fromARGB(255, 220, 104, 8)),
        ),
      );
    }).toList();

    setState(() => nearbyMarkers = markers);
  }

  void _changeRadius(double radius) {
    setState(() {
      selectedRadius = radius;
    });
    _loadNearbyLocations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final scaffoldColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: const Text("الخريطة"),
        backgroundColor: primaryColor,
        actions: [
          if (!widget.justForShow)
            PopupMenuButton<double>(
              onSelected: _changeRadius,
              icon: const Icon(Icons.filter_alt),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 5, child: Text("5 كم")),
                PopupMenuItem(value: 10, child: Text("10 كم")),
                PopupMenuItem(value: 20, child: Text("20 كم")),
              ],
            ),
        ],
      ),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.oldPoint ??
                    LatLng(userLocation!.latitude, userLocation!.longitude),
                initialZoom: zoom,
                onTap: (tapPosition, point) {
                  if (!widget.justForShow) {
                    setState(() {
                      _pickedLocation = point;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tourist_guide',
                ),
                MarkerLayer(
                  markers: [
                    // Marker المستخدم
                    Marker(
                      width: 60,
                      height: 60,
                      point: LatLng(
                          userLocation!.latitude, userLocation!.longitude),
                      child: const Icon(Icons.person_pin_circle,
                          size: 50, color: Colors.blue),
                    ),
                   
                    // Markers المعالم القريبة
                    ...nearbyMarkers,
                  ],
                ),
              ],
            ),
    );
  }
}
