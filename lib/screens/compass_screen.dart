import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'dart:async';

class CompassScreen extends StatefulWidget {
  const CompassScreen({Key? key}) : super(key: key);

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen>
    with TickerProviderStateMixin {
  double _heading = 0.0;
  double _qiblaDirection = 0.0;
  Position? _currentPosition;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasPermissions = false;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNearQibla = false;

  // Kabe koordinatları
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _initializeCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCompass() async {
    try {
      await _checkPermissions();
      
      if (_hasPermissions) {
        await _getCurrentLocation();
        await _startCompass();
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Konum ve pusula izinleri gerekli';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    var sensorPermission = await Permission.sensors.status;
    if (sensorPermission.isDenied) {
      sensorPermission = await Permission.sensors.request();
    }

    _hasPermissions = locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always;
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition != null) {
        _qiblaDirection = _calculateQiblaDirection(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }
    } catch (e) {
      print('Konum alınamadı: $e');
      setState(() {
        _errorMessage = 'Konum alınamadı: $e';
      });
    }
  }

  Future<void> _startCompass() async {
    if (await FlutterCompass.events != null) {
      _compassSubscription = FlutterCompass.events!.listen(
        (CompassEvent compass) {
          if (mounted && compass.heading != null) {
            setState(() {
              _heading = compass.heading!;
              _checkQiblaAlignment();
            });
          }
        },
        onError: (error) {
          print('Pusula hatası: $error');
          setState(() {
            _errorMessage = 'Pusula hatası: $error';
          });
        },
      );
    } else {
      setState(() {
        _errorMessage = 'Bu cihazda pusula sensörü bulunmuyor';
      });
    }
  }

  void _checkQiblaAlignment() {
    double qiblaAngle = _qiblaAngle;
    // Kıble yönünde ±10 derece tolerans
    _isNearQibla = (qiblaAngle <= 10 || qiblaAngle >= 350);
  }

  double _calculateQiblaDirection(double lat, double lng) {
    double dLng = (kaabaLng - lng) * (math.pi / 180);
    double lat1 = lat * (math.pi / 180);
    double lat2 = kaabaLat * (math.pi / 180);

    double y = math.sin(dLng) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    double bearing = math.atan2(y, x) * (180 / math.pi);
    return (bearing + 360) % 360;
  }

  double get _qiblaAngle {
    return (_qiblaDirection - _heading + 360) % 360;
  }

  // Cihaz yönü - Kıble farkı
  double get _deviceAngle {
    return (_heading + 360) % 360;
  }

  // Kıble ile cihaz arasındaki fark
  double get _angleDifference {
    double diff = (_qiblaDirection - _heading).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text(
                'Pusula hazırlanıyor...',
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _initializeCompass();
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          // Sensör durumu
          _buildSensorStatus(),
          
          const SizedBox(height: 40),
          
          // Ana pusula
          Expanded(
            child: Center(
              child: _buildMainCompass(),
            ),
          ),
          
          // Kıble durumu
          _buildQiblaStatus(),
          
          const SizedBox(height: 20),
          
          // Alt bilgi paneli
          _buildBottomInfo(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.teal,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: const Text(
        'Kıble Pusulası',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _getCurrentLocation(),
          icon: const Icon(Icons.my_location, color: Colors.white),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSensorStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            'Sensör Aktif',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCompass() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dış çember - yeşil gradient
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade300,
                  Colors.green.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // İç beyaz çember
          Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          
          // Derece işaretleri
          Transform.rotate(
            angle: -_heading * (math.pi / 180),
            child: _buildCompassMarks(),
          ),
          
          // Yön etiketleri
          Transform.rotate(
            angle: -_heading * (math.pi / 180),
            child: _buildDirectionLabels(),
          ),
          
          // Kıble göstergesi
          Transform.rotate(
            angle: _qiblaAngle * (math.pi / 180),
            child: _buildQiblaPointer(),
          ),
          
          // Merkez nokta
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassMarks() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        children: List.generate(36, (index) {
          final angle = index * 10.0;
          final isMainMark = angle % 90 == 0;
          
          return Transform.rotate(
            angle: angle * (math.pi / 180),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: isMainMark ? 3 : 1,
                height: isMainMark ? 20 : 10,
                margin: const EdgeInsets.only(top: 10),
                color: Colors.grey.shade400,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDirectionLabels() {
    final directions = [
      {'angle': 0.0, 'label': 'K'},
      {'angle': 90.0, 'label': 'D'},
      {'angle': 180.0, 'label': 'G'},
      {'angle': 270.0, 'label': 'B'},
    ];

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        children: directions.map((direction) {
          final angle = direction['angle'] as double;
          final label = direction['label'] as String;
          
          return Transform.rotate(
            angle: angle * (math.pi / 180),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 35),
                child: Transform.rotate(
                  angle: _heading * (math.pi / 180),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQiblaPointer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kıble etiketi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'KIBLE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Kırmızı ok işareti
        const SizedBox(height: 4),
        Container(
          width: 0,
          height: 0,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(width: 6, color: Colors.transparent),
              right: BorderSide(width: 6, color: Colors.transparent),
              bottom: BorderSide(width: 10, color: Colors.red),
            ),
          ),
        ),
        
        // Yeşil daire
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_upward,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildQiblaStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isNearQibla ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _isNearQibla ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isNearQibla ? Icons.check_circle : Icons.info,
            color: _isNearQibla ? Colors.green.shade700 : Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isNearQibla ? 'KIBLE YÖNÜNDE HIZALI!' : 'Kıble yönünü bulun',
              style: TextStyle(
                color: _isNearQibla ? Colors.green.shade700 : Colors.orange.shade700,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoColumn('Cihaz', '${_deviceAngle.round()}°', Colors.blue),
          _buildInfoColumn('Kıble', '${_qiblaDirection.round()}°', Colors.green),
          _buildInfoColumn('Fark', '${_angleDifference.round()}°', Colors.green),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}