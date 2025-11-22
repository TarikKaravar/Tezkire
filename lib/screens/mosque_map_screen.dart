import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // OSM Harita
import 'package:latlong2/latlong.dart'; // Koordinat
import 'package:geolocator/geolocator.dart'; // Konum
import 'package:http/http.dart' as http; // API
import 'package:flutter_app/screens/app_colors.dart'; // Renkler

class MosqueMapScreen extends StatefulWidget {
  const MosqueMapScreen({super.key});

  @override
  State<MosqueMapScreen> createState() => _MosqueMapScreenState();
}

class _MosqueMapScreenState extends State<MosqueMapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(41.0082, 28.9784); // Varsayılan: İstanbul
  List<Marker> _mosqueMarkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Konum servisi açık mı?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 2. İzin kontrolü
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 3. Konumu al
    try {
      Position position = await Geolocator.getCurrentPosition();
      
      // EKRAN KAPANDIYSA DUR (HATA ÇÖZÜMÜ)
      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _mapController.move(_currentPosition, 15.0);
      
      // Camileri getir
      _fetchNearbyMosques();
      
    } catch (e) {
      debugPrint("Konum hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearbyMosques() async {
    double lat = _currentPosition.latitude;
    double lon = _currentPosition.longitude;
    
    // Overpass API sorgusu (2km yarıçap)
    String url = 'https://overpass-api.de/api/interpreter?data=[out:json];node["amenity"="place_of_worship"]["religion"="muslim"](around:2000,$lat,$lon);out;';

    try {
      final response = await http.get(Uri.parse(url));
      
      // EKRAN KAPANDIYSA DUR (HATA ÇÖZÜMÜ)
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final elements = data['elements'] as List;

        setState(() {
          _mosqueMarkers = elements.map((e) {
            return Marker(
              point: LatLng(e['lat'], e['lon']),
              width: 80,
              height: 80,
              child: Column(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 40),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)]
                    ),
                    child: Text(
                      e['tags']['name'] ?? 'Cami', 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context)
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("API Hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tezkire',
              ),
              MarkerLayer(
                markers: [
                  // Kullanıcı Konumu (Mavi Nokta)
                  Marker(
                    point: _currentPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
                  ),
                  // Camiler
                  ..._mosqueMarkers,
                ],
              ),
            ],
          ),
          
          // Yükleniyor göstergesi (Haki Yeşil)
          if (_isLoading) 
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // Konuma Git Butonu (Haki Yeşil)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.primary, 
              onPressed: _determinePosition,
              child: const Icon(Icons.gps_fixed, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}