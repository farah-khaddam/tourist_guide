// map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  final double initialRadius; // بالكيلومتر
  final LatLng? oldPoint;
  final bool justForShow;

  const MapScreen({
    super.key,
    required this.initialRadius,
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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    setState(() => userLocation = pos);
    _loadNearbyLocations();
  }

  Future<void> _loadNearbyLocations() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('location').get();
    final docs = snapshot.docs;
    const Distance distance = Distance();

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

      return d <= widget.initialRadius;
    }).toList();

    final markers = filtered.map((doc) {
      final data = doc.data();
      return Marker(
        width: 50,
        height: 50,
        point: LatLng(data['latitude'], data['longitude']),
        child: Tooltip(
          message: data['name'] ?? 'موقع',
          child: const Icon(Icons.location_on, size: 40, color: Colors.red),
        ),
      );
    }).toList();

    setState(() => nearbyMarkers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("الخريطة"), backgroundColor: Colors.teal),
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
                    // Marker الموقع المختار
                    if (_pickedLocation != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _pickedLocation!,
                        child: const Icon(Icons.location_on,
                            size: 40, color: Colors.green),
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
