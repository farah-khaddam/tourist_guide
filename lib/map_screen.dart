// map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  final double initialRadius; // بالكيلومتر
  const MapScreen({super.key, required this.initialRadius});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? userLocation;
  List<Marker> nearbyMarkers = [];

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
    final Distance distance = const Distance();

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
              options: MapOptions(
                center: LatLng(userLocation!.latitude, userLocation!.longitude),
                zoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tourist_guide',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60,
                      height: 60,
                      point: LatLng(
                          userLocation!.latitude, userLocation!.longitude),
                      child: const Icon(Icons.person_pin_circle,
                          size: 50, color: Colors.blue),
                    ),
                    ...nearbyMarkers,
                  ],
                ),
              ],
            ),
    );
  }
}
