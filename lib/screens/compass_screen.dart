import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CompassScreen extends StatefulWidget {
  @override
  _CompassScreenState createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> with TickerProviderStateMixin {
  double _deviceHeading = 0.0;
  Position? _userPosition;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _compassAvailable = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final double _kaabaLat = 21.4225;
  final double _kaabaLng = 39.8262;

  // Sensor verileri için
  List<double> _magnetometerValues = [0, 0, 0];
  List<double> _accelerometerValues = [0, 0, 0];
  
  // Filtreleme için
  List<double> _headingHistory = [];
  static const int _historySize = 10;
  static const double _smoothingFactor = 0.8;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initialize();
    _startSensorListening();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initialize() async {
    try {
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

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Konum servisi kapalı. Lütfen GPS\'i açın.';
          _isLoading = false;
        });
        return;
      }

      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 15),
      );

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Konum hatası: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startSensorListening() {
    try {
      // Manyetometre dinleme
      _magnetometerSubscription = magnetometerEvents.listen(
        (MagnetometerEvent event) {
          _magnetometerValues = [event.x, event.y, event.z];
          _updateHeading();
        },
        onError: (error) {
          setState(() {
            _compassAvailable = false;
            _errorMessage = 'Manyetometre hatası: Sensör verileri alınamıyor. Cihazı kalibre edin.';
          });
        },
      );

      // Akselerometre dinleme
      _accelerometerSubscription = accelerometerEvents.listen(
        (AccelerometerEvent event) {
          _accelerometerValues = [event.x, event.y, event.z];
          _updateHeading();
        },
        onError: (error) {
          setState(() {
            _compassAvailable = false;
            _errorMessage = 'Akselerometre hatası: Sensör verileri alınamıyor. Cihazı kalibre edin.';
          });
        },
      );

    } catch (e) {
      setState(() {
        _compassAvailable = false;
        _errorMessage = 'Sensör başlatma hatası: $e';
      });
    }
  }

  void _updateHeading() {
    if (!mounted) return;

    try {
      double magneticStrength = sqrt(
        _magnetometerValues[0] * _magnetometerValues[0] +
        _magnetometerValues[1] * _magnetometerValues[1] +
        _magnetometerValues[2] * _magnetometerValues[2]
      );

      if (magneticStrength < 15.0) {
        print('Zayıf manyetik alan: $magneticStrength');
        setState(() {
          _compassAvailable = false;
          _errorMessage = 'Zayıf manyetik alan algılandı. Lütfen cihazı kalibre edin.';
        });
        return;
      }

      double heading = _calculateHeadingWithTilt();
      double smoothedHeading = _applySmoothingFilter(heading);

      print('Cihaz Yönelimi: $smoothedHeading, Kıble Açısı: ${_calculateQiblaAngle(_userPosition!.latitude, _userPosition!.longitude)}');

      setState(() {
        _deviceHeading = smoothedHeading;
        _compassAvailable = true;
      });

    } catch (e) {
      print('Başlık hesaplama hatası: $e');
    }
  }

  double _calculateHeadingWithTilt() {
    double magX = _magnetometerValues[0];
    double magY = _magnetometerValues[1];
    double magZ = _magnetometerValues[2];
    
    double accX = _accelerometerValues[0];
    double accY = _accelerometerValues[1];
    double accZ = _accelerometerValues[2];

    double accMagnitude = sqrt(accX * accX + accY * accY + accZ * accZ);
    if (accMagnitude == 0) return _deviceHeading;

    accX /= accMagnitude;
    accY /= accMagnitude;
    accZ /= accMagnitude;

    double hX = magY * accZ - magZ * accY;
    double hY = magZ * accX - magX * accZ;
    
    double heading = atan2(hY, hX) * 180 / pi;
    
    heading = (heading + 360) % 360;
    
    return heading;
  }

  double _applySmoothingFilter(double newHeading) {
    _headingHistory.add(newHeading);
    if (_headingHistory.length > _historySize) {
      _headingHistory.removeAt(0);
    }
    
    if (_headingHistory.length == 1) return newHeading;
    
    double sinSum = 0, cosSum = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < _headingHistory.length; i++) {
      double weight = (i + 1) / _headingHistory.length;
      double radians = _headingHistory[i] * pi / 180;
      sinSum += sin(radians) * weight;
      cosSum += cos(radians) * weight;
      totalWeight += weight;
    }
    
    double avgRadians = atan2(sinSum / totalWeight, cosSum / totalWeight);
    double smoothedHeading = (avgRadians * 180 / pi + 360) % 360;
    
    return smoothedHeading;
  }

  double _calculateQiblaAngle(double userLat, double userLng) {
    double userLatRad = userLat * pi / 180;
    double userLngRad = userLng * pi / 180;
    double kaabaLatRad = _kaabaLat * pi / 180;
    double kaabaLngRad = _kaabaLng * pi / 180;

    double deltaLng = kaabaLngRad - userLngRad;
    
    double y = sin(deltaLng) * cos(kaabaLatRad);
    double x = cos(userLatRad) * sin(kaabaLatRad) - 
               sin(userLatRad) * cos(kaabaLatRad) * cos(deltaLng);

    double bearing = atan2(y, x);
    
    double qiblaAngle = (bearing * 180 / pi + 360) % 360;
    
    return qiblaAngle;
  }

  double _getQiblaDisplayAngle(double qiblaAngle) {
    double displayAngle = (qiblaAngle - _deviceHeading + 360) % 360;
    return displayAngle;
  }

  bool _isQiblaAligned() {
    if (_userPosition == null) return false;

    final qiblaAngle = _calculateQiblaAngle(_userPosition!.latitude, _userPosition!.longitude);
    double angleDiff = (qiblaAngle - _deviceHeading + 360) % 360;

    return angleDiff <= 15 || angleDiff >= 345;
  }

  void _triggerHapticFeedback() {
    if (_isQiblaAligned()) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Kıble Pusulası", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location_rounded),
            onPressed: _recalibrate,
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  void _recalibrate() {
    _headingHistory.clear();
    _triggerHapticFeedback();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pusula kalibre edildi'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.teal[600],
      ),
    );
  }

  void _refresh() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _compassAvailable = false;
    });
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _headingHistory.clear();
    _initialize();
    _startSensorListening();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.teal[700],
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Konum ve sensörler hazırlanıyor...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
              Text(
                'Cihazı 8 şeklinde hareket ettirerek kalibre edin veya GPS\'i kontrol edin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: Icon(Icons.refresh),
                label: Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_userPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal[700]),
            SizedBox(height: 20),
            Text(
              'Konum verisi bekleniyor...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return _buildCompass();
  }

  Widget _buildCompass() {
    final qiblaAngle = _calculateQiblaAngle(_userPosition!.latitude, _userPosition!.longitude);
    final qiblaDisplayAngle = _getQiblaDisplayAngle(qiblaAngle);
    final isAligned = _isQiblaAligned();

    if (isAligned) {
      _triggerHapticFeedback();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _compassAvailable ? Colors.green[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _compassAvailable ? Colors.green[300]! : Colors.orange[300]!,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _compassAvailable ? Icons.sensors : Icons.warning_amber_rounded,
                  color: _compassAvailable ? Colors.green[700] : Colors.orange[700],
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  _compassAvailable ? 'Sensör Aktif' : 'Sensör Hatası',
                  style: TextStyle(
                    color: _compassAvailable ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 360,
            height: 360,
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAligned ? Colors.green : Colors.grey[300]!,
                      width: isAligned ? 6 : 3,
                    ),
                    boxShadow: isAligned ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ] : [],
                  ),
                ),

                Container(
                  width: 330,
                  height: 330,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.teal[700]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildCompassMarks(),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.teal[700],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ],
                  ),
                ),

                Transform.rotate(
                  angle: qiblaDisplayAngle * pi / 180,
                  child: Container(
                    width: 360,
                    height: 360,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: isAligned ? _pulseAnimation.value : 1.0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isAligned ? Colors.green[600] : Colors.teal[600],
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'KIBLE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isAligned ? Colors.green[600] : Colors.teal[600],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                Container(
                  width: 360,
                  height: 360,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 8,
                      height: 35,
                      margin: EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isAligned ? Colors.green[700] : Colors.red[600],
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          _buildStatusCard(qiblaAngle, qiblaDisplayAngle, isAligned),

          SizedBox(height: 20),

          _buildLocationCard(),

          SizedBox(height: 20),

          _buildInstructionsCard(),

          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCompassMarks() {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = 0; i < 4; i++)
          Transform.rotate(
            angle: i * pi / 2,
            child: Container(
              width: 330,
              height: 330,
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      child: Transform.rotate(
                        angle: -i * pi / 2,
                        child: Text(
                          ['K', 'D', 'G', 'B'][i],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: i == 0 ? Colors.red[600] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 28,
                      margin: EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: i == 0 ? Colors.red[600] : Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        for (int i = 0; i < 12; i++)
          if (i % 3 != 0)
            Transform.rotate(
              angle: i * pi / 6,
              child: Container(
                width: 330,
                height: 330,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 22),
                    width: 2,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildStatusCard(double qiblaAngle, double displayAngle, bool isAligned) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isAligned ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAligned ? Colors.green[200]! : Colors.orange[200]!,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAligned ? Icons.check_circle_rounded : Icons.adjust_rounded,
                    color: isAligned ? Colors.green[700] : Colors.orange[700],
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAligned ? 'KIBLE YÖNÜNDE HIZALI!' : 'KIBLE YÖNÜNE ÇEVİRİN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isAligned ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAngleInfo('Cihaz', '${_deviceHeading.toStringAsFixed(0)}°', Colors.blue),
                _buildAngleInfo('Kıble', '${qiblaAngle.toStringAsFixed(0)}°', Colors.teal),
                _buildAngleInfo('Fark', '${displayAngle.toStringAsFixed(0)}°', 
                    isAligned ? Colors.green : Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    if (_userPosition == null) return Container();
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal[700], size: 24),
                SizedBox(width: 8),
                Text(
                  'Konum Bilgisi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enlem:', style: TextStyle(color: Colors.grey[600])),
                    Text('${_userPosition!.latitude.toStringAsFixed(4)}°',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Boylam:', style: TextStyle(color: Colors.grey[600])),
                    Text('${_userPosition!.longitude.toStringAsFixed(4)}°',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Doğruluk: ±${_userPosition!.accuracy.toStringAsFixed(0)}m',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal[700], size: 24),
                SizedBox(width: 8),
                Text(
                  'Kullanım Kılavuzu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Telefonu yatay düzlemde (masa gibi) tutun\n'
              '• Yeşil KIBLE oku her zaman Kabe\'nin gerçek yönünü gösterir\n'
              '• Kendinizi (telefonu değil) çevirin\n'
              '• Yeşil oku üstteki kırmızı çizgi ile hizalayın\n'
              '• Hizalandığında çerçeve yeşil olur ve titreşim hissedersiniz\n'
              '• Metal eşyalardan ve elektronik cihazlardan uzak durun\n'
              '• Kalibrasyon için cihazı 8 şeklinde hareket ettirin\n'
              '• Sensör hatası alırsanız, cihazı açık alanda kalibre edin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}