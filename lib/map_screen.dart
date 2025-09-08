// map_screen.dart
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_details_page.dart';

class MapScreen extends StatefulWidget {
  final LatLng? oldPoint;
  final bool justForShow;

  const MapScreen({super.key, this.oldPoint, this.justForShow = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  Position? userLocation;
  List<Marker> nearbyMarkers = [];
  LatLng? _pickedLocation;
  double zoom = 13.0;

  double? filterDistanceKm; // null = كل المعالم
  List<Map<String, dynamic>> allMarkersData = []; // تحميل المعالم مرة واحدة

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى تفعيل خدمة الموقع")));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("تم رفض إذن الموقع")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("تم رفض إذن الموقع بشكل دائم. يرجى تمكينه من إعدادات الهاتف")));
      return;
    }

    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    setState(() => userLocation = pos);
    _loadNearbyLocations(initialLoad: true);
  }

  Future<void> _loadNearbyLocations({bool initialLoad = false}) async {
    if (userLocation == null) return;

    if (initialLoad) {
      final snapshot =
          await FirebaseFirestore.instance.collection('location').get();

      allMarkersData.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<String> images = List<String>.from(data['images'] ?? []);
        final lat = (data['latitude'] as num).toDouble();
        final lng = (data['longitude'] as num).toDouble();

        final ratingsSnapshot = await FirebaseFirestore.instance
            .collection('location')
            .doc(doc.id)
            .collection('ratings')
            .get();

        double averageRating = 0;
        int ratingsCount = ratingsSnapshot.docs.length;

        if (ratingsCount > 0) {
          double sum = 0;
          for (var r in ratingsSnapshot.docs) {
            sum += (r['rating'] ?? 0).toDouble();
          }
          averageRating = sum / ratingsCount;
        }

        allMarkersData.add({
          'doc': doc,
          'data': data,
          'lat': lat,
          'lng': lng,
          'images': images,
          'averageRating': averageRating,
          'ratingsCount': ratingsCount,
        });
      }
    }

    final List<Marker> markers = [];
    for (var item in allMarkersData) {
      final distance = _calculateDistance(userLocation!.latitude,
          userLocation!.longitude, item['lat'], item['lng']);
      if (filterDistanceKm != null && distance > filterDistanceKm!) continue;

      markers.add(
        Marker(
          width: 150,
          height: 70,
          point: LatLng(item['lat'], item['lng']),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  item['data']['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  _showLocationBottomSheet(
                    item['doc'],
                    item['lat'],
                    item['lng'],
                    item['images'],
                    item['averageRating'],
                    item['ratingsCount'],
                  );
                },
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Color.fromARGB(255, 220, 104, 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    setState(() => nearbyMarkers = markers);
  }

  void _showLocationBottomSheet(
      QueryDocumentSnapshot doc,
      double lat,
      double lng,
      List<String> images,
      double averageRating,
      int ratingsCount) {
    final distance = _calculateDistance(
        userLocation!.latitude, userLocation!.longitude, lat, lng);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc['name'] ?? 'موقع',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (images.isNotEmpty)
              SizedBox(
                height: 180,
                child: PageView.builder(
                  itemCount: images.length,
                  controller: PageController(viewportFraction: 0.9),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Text("لا توجد صور متاحة لهذا الموقع"),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place, color: Colors.redAccent),
                const SizedBox(width: 5),
                Text("${distance.toStringAsFixed(2)} كم"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 5),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 5),
                Text("($ratingsCount تقييم)"),
              ],
            ),
            const SizedBox(height: 15),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            LocationDetailsPage(locationId: doc.id)),
                  );
                },
                child: const Text("عرض التفاصيل"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("اختر مسافة"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("5 كم"),
              onTap: () => Navigator.pop(ctx, 5.0),
            ),
            ListTile(
              title: const Text("10 كم"),
              onTap: () => Navigator.pop(ctx, 10.0),
            ),
            ListTile(
              title: const Text("20 كم"),
              onTap: () => Navigator.pop(ctx, 20.0),
            ),
            ListTile(
              title: const Text("أكثر"),
              onTap: () => Navigator.pop(ctx, null),
            ),
          ],
        ),
      ),
    ).then((selected) {
      if (selected == null && filterDistanceKm == null) return;

      setState(() => filterDistanceKm = selected);
      _loadNearbyLocations(initialLoad: false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selected != null
              ? "تم اختيار $selected كم"
              : "تم عرض كل المعالم"),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("الخريطة"),
        backgroundColor: theme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
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
                    setState(() => _pickedLocation = point);
                  }
                },
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
                      width: 60,
                      height: 60,
                      point: LatLng(userLocation!.latitude,
                          userLocation!.longitude),
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 50,
                        color: Colors.blue,
                      ),
                    ),
                    ...nearbyMarkers,
                  ],
                ),
              ],
            ),
    );
  }
}
