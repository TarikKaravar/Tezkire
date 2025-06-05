import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class CompassScreen extends StatefulWidget {
  @override
  _CompassScreenState createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? _deviceHeading;
  Position? _userPosition;
  bool _isLoading = true;
  String? _errorMessage;

  final double _kaabaLat = 21.4225;
  final double _kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Geolocator'un kendi permission sistemini kullan
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Konum izni reddedildi';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.';
          _isLoading = false;
        });
        return;
      }

      // Konum servisinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Konum servisi kapalı. Lütfen GPS\'i açın.';
          _isLoading = false;
        });
        return;
      }

      // Konumu al
      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Compass dinleyicisini başlat
      FlutterCompass.events?.listen((event) {
        if (mounted) {
          setState(() {
            _deviceHeading = event.heading;
            _isLoading = false;
          });
        }
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  double _calculateQiblaAngle(double userLat, double userLng) {
    double latRad = userLat * pi / 180;
    double lngRad = userLng * pi / 180;
    double kaabaLatRad = _kaabaLat * pi / 180;
    double kaabaLngRad = _kaabaLng * pi / 180;

    double deltaLng = kaabaLngRad - lngRad;

    double x = sin(deltaLng);
    double y = cos(latRad) * tan(kaabaLatRad) - sin(latRad) * cos(deltaLng);

    double angle = atan2(x, y);
    return (angle * 180 / pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kıble Pusulası"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Konum ve pusula yükleniyor...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initialize();
                },
                child: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_deviceHeading == null || _userPosition == null) {
      return Center(
        child: Text('Pusula verisi bekleniyor...'),
      );
    }

    final qiblaDirection = _calculateQiblaAngle(
      _userPosition!.latitude, 
      _userPosition!.longitude
    );
    final rotationAngle = ((_deviceHeading! - qiblaDirection) * (pi / 180)) * -1;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Kıble Yönü',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: Transform.rotate(
              angle: rotationAngle,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Kıble yönü işareti
                    Positioned(
                      top: 20,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    // Merkez noktası
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Pusula işaretleri
                    ...List.generate(12, (index) {
                      return Transform.rotate(
                        angle: index * pi / 6,
                        child: Positioned(
                          top: 30,
                          child: Container(
                            width: 2,
                            height: 15,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Yeşil ok Kıble yönünü gösteriyor',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Açı: ${qiblaDirection.toStringAsFixed(1)}°',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}