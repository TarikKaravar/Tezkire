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
  bool _compassAvailable = false;
  Timer? _simulationTimer;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final double _kaabaLat = 21.4225;
  final double _kaabaLng = 39.8262;

  // Filtreleme ve kalibrasyon
  List<double> _headingHistory = [];
  double _filteredHeading = 0.0;
  static const double _filterFactor = 0.15;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initialize();
    _startCompassListening();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startCompassListening() {
    try {
      _magnetometerSubscription = magnetometerEvents.listen(
        (MagnetometerEvent event) {
          if (mounted) {
            double rawHeading = _calculateHeading(event.x, event.y, event.z);
            _filteredHeading = _applySmoothing(rawHeading);
            
            setState(() {
              _deviceHeading = _filteredHeading;
              _compassAvailable = true;
            });
          }
        },
        onError: (error) {
          _startSimulationMode();
        },
      );
      
      Timer(Duration(seconds: 3), () {
        if (!_compassAvailable) {
          _startSimulationMode();
        }
      });
      
    } catch (e) {
      _startSimulationMode();
    }
  }

  double _calculateHeading(double x, double y, double z) {
    double heading = atan2(y, x) * (180 / pi);
    heading = (heading + 360) % 360;
    // Android ve iOS için orientasyon düzeltmesi
    heading = (360 - heading) % 360;
    return heading;
  }

  double _applySmoothing(double newHeading) {
    _headingHistory.add(newHeading);
    if (_headingHistory.length > 5) {
      _headingHistory.removeAt(0);
    }
    
    if (_headingHistory.length == 1) return newHeading;
    
    // Dairesel ortalama hesapla (360° geçişi için)
    double sinSum = 0, cosSum = 0;
    for (double heading in _headingHistory) {
      double radians = heading * pi / 180;
      sinSum += sin(radians);
      cosSum += cos(radians);
    }
    
    double avgRadians = atan2(sinSum / _headingHistory.length, cosSum / _headingHistory.length);
    return (avgRadians * 180 / pi + 360) % 360;
  }

  void _startSimulationMode() {
    setState(() {
      _compassAvailable = false;
    });
    
    double simulatedHeading = 0.0;
    _simulationTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted) {
        simulatedHeading = (simulatedHeading + 1) % 360;
        setState(() {
          _deviceHeading = simulatedHeading;
        });
      } else {
        timer.cancel();
      }
    });
  }

  double _calculateQiblaAngle(double userLat, double userLng) {
    double userLatRad = userLat * pi / 180;
    double userLngRad = userLng * pi / 180;
    double kaabaLatRad = _kaabaLat * pi / 180;
    double kaabaLngRad = _kaabaLng * pi / 180;

    double deltaLng = kaabaLngRad - userLngRad;
    
    double x = sin(deltaLng) * cos(kaabaLatRad);
    double y = cos(userLatRad) * sin(kaabaLatRad) - 
               sin(userLatRad) * cos(kaabaLatRad) * cos(deltaLng);

    double bearing = atan2(x, y);
    return (bearing * 180 / pi + 360) % 360;
  }

  // Kıble okun ekranda gösterileceği açı (telefon yöneliminden bağımsız)
  double _getQiblaDisplayAngle(double qiblaAngle) {
    // Kıble açısından cihaz yönelimini çıkar
    return (qiblaAngle - _deviceHeading + 360) % 360;
  }

  bool _isQiblaAligned() {
    if (_userPosition == null) return false;
    final qiblaAngle = _calculateQiblaAngle(_userPosition!.latitude, _userPosition!.longitude);
    final displayAngle = _getQiblaDisplayAngle(qiblaAngle);
    // Üst kısım (±20 derece tolerans)
    return displayAngle <= 20 || displayAngle >= 340;
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
            icon: Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
                _compassAvailable = false;
              });
              _magnetometerSubscription?.cancel();
              _simulationTimer?.cancel();
              _initialize();
              _startCompassListening();
            },
          ),
        ],
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
              color: Colors.teal[700],
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Konum tespit ediliyor...',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initialize();
                },
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
        child: Text(
          'Konum verisi bekleniyor...',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return _buildCompass();
  }

  Widget _buildCompass() {
    final qiblaAngle = _calculateQiblaAngle(_userPosition!.latitude, _userPosition!.longitude);
    final qiblaDisplayAngle = _getQiblaDisplayAngle(qiblaAngle);
    final isAligned = _isQiblaAligned();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Durum göstergesi
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
                  _compassAvailable ? 'Sensör Aktif' : 'Simülasyon Modu',
                  style: TextStyle(
                    color: _compassAvailable ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Ana pusula
          Container(
            width: 350,
            height: 350,
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dış çember - hizalama göstergesi
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAligned ? Colors.green : Colors.grey[300]!,
                      width: isAligned ? 8 : 4,
                    ),
                    boxShadow: isAligned ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ] : [],
                  ),
                ),

                // Ana pusula gövdesi
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.teal[700]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pusula işaretleri ve harfler
                      _buildCompassMarks(),
                      
                      // Merkez noktası
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.teal[700],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),

                // DİNAMİK KIBLE GÖSTERGESİ - Bu her zaman Kabe'yi gösterir!
                Transform.rotate(
                  angle: qiblaDisplayAngle * pi / 180,
                  child: Container(
                    width: 350,
                    height: 350,
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
                                // Kıble etiketi
                                Container(
                                  margin: EdgeInsets.only(top: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isAligned ? Colors.green : Colors.teal[600],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'KIBLE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Kıble oku
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isAligned ? Colors.green : Colors.teal[600],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 28,
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

                // Üst referans çizgisi
                Container(
                  width: 350,
                  height: 350,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 6,
                      height: 30,
                      margin: EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isAligned ? Colors.green : Colors.red[600],
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
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

          // Durum kartı
          _buildStatusCard(qiblaAngle, qiblaDisplayAngle, isAligned),

          SizedBox(height: 20),

          // Kullanım talimatları
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
        // Ana yön işaretleri (K, D, G, B)
        for (int i = 0; i < 4; i++)
          Transform.rotate(
            angle: i * pi / 2,
            child: Container(
              width: 320,
              height: 320,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: i == 0 ? Colors.red[600] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 25,
                      margin: EdgeInsets.only(top: 5),
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
        
        // Ara işaretler (her 30 derece)
        for (int i = 0; i < 12; i++)
          if (i % 3 != 0) // Ana yönleri atla
            Transform.rotate(
              angle: i * pi / 6,
              child: Container(
                width: 320,
                height: 320,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 20),
                    width: 2,
                    height: 15,
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
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Hizalama durumu
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAligned ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isAligned ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAligned ? Icons.check_circle_rounded : Icons.adjust_rounded,
                    color: isAligned ? Colors.green[700] : Colors.orange[700],
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAligned ? 'KIBLE YÖNÜNDE!' : 'KIBLE YÖNÜNE ÇEVİRİN',
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
            
            // Açı bilgileri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAngleInfo('Cihaz Yönü', '${_deviceHeading.toStringAsFixed(1)}°', Colors.blue),
                _buildAngleInfo('Kıble Açısı', '${qiblaAngle.toStringAsFixed(1)}°', Colors.teal),
                _buildAngleInfo('Fark', '${displayAngle.toStringAsFixed(1)}°', 
                    isAligned ? Colors.green : Colors.orange),
              ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal[700], size: 24),
                SizedBox(width: 8),
                Text(
                  'Kullanım Talimatları',
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
              '• Telefonu yatay düzlemde tutun\n'
              '• Yeşil KIBLE oku her zaman Kabe\'yi gösterir\n'
              '• Telefonu çevirin ve yeşil oku üstteki çizgi ile hizalayın\n'
              '• Hizalandığında çerçeve yeşil olur ve titreşim hissedersiniz\n'
              '• Metal objelerden ve manyetik alanlardan uzak durun',
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
    _simulationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}