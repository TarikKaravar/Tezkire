import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart'; // Added for consistent typography

class CompassScreen extends StatefulWidget {
  const CompassScreen({Key? key}) : super(key: key);

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> with TickerProviderStateMixin {
  double _yon = 0.0;
  double _kibleYonu = 0.0;
  Position? _mevcutKonum;
  StreamSubscription<CompassEvent>? _pusulaAboneligi;
  bool _izinlerVar = false;
  bool _yukleniyor = true;
  String _hataMesaji = '';
  bool _kibleyeYakin = false;

  // Animasyon kontrolcüsü
  late AnimationController _animasyonKontrolcusu;
  late Animation<double> _pusulaAnimasyonu;

  // Kabe koordinatları
  static const double kabeEnlem = 21.4225;
  static const double kabeBoylam = 39.8262;

  @override
  void initState() {
    super.initState();
    // Animasyon kontrolcüsünü başlat
    _animasyonKontrolcusu = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pusulaAnimasyonu = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animasyonKontrolcusu, curve: Curves.easeOut),
    );
    _pusulayiBaslat();
  }

  @override
  void dispose() {
    _pusulaAboneligi?.cancel();
    _animasyonKontrolcusu.dispose();
    super.dispose();
  }

  Future<void> _pusulayiBaslat() async {
    try {
      await _izinleriKontrolEt();

      if (_izinlerVar) {
        await _mevcutKonumuAl();
        await _pusulayiCalistir();

        setState(() {
          _yukleniyor = false;
        });
        _animasyonKontrolcusu.forward();
      } else {
        setState(() {
          _hataMesaji = 'Konum ve pusula izinleri gerekli';
          _yukleniyor = false;
        });
      }
    } catch (e) {
      setState(() {
        _hataMesaji = 'Hata: $e';
        _yukleniyor = false;
      });
    }
  }

  Future<void> _izinleriKontrolEt() async {
    LocationPermission konumIzni = await Geolocator.checkPermission();
    if (konumIzni == LocationPermission.denied) {
      konumIzni = await Geolocator.requestPermission();
    }

    var sensorIzni = await Permission.sensors.status;
    if (sensorIzni.isDenied) {
      sensorIzni = await Permission.sensors.request();
    }

    _izinlerVar = konumIzni == LocationPermission.whileInUse ||
        konumIzni == LocationPermission.always;
  }

  Future<void> _mevcutKonumuAl() async {
    try {
      _mevcutKonum = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_mevcutKonum != null) {
        _kibleYonu = _kibleYonunuHesapla(
          _mevcutKonum!.latitude,
          _mevcutKonum!.longitude,
        );
      }
    } catch (e) {
      print('Konum alınamadı: $e');
      setState(() {
        _hataMesaji = 'Konum alınamadı: $e';
      });
    }
  }

  Future<void> _pusulayiCalistir() async {
    if (await FlutterCompass.events != null) {
      _pusulaAboneligi = FlutterCompass.events!.listen(
        (CompassEvent pusula) {
          if (mounted && pusula.heading != null) {
            setState(() {
              _yon = pusula.heading!;
              _kibleHizasiniKontrolEt();
            });
            _animasyonKontrolcusu.forward();
          }
        },
        onError: (hata) {
          print('Pusula hatası: $hata');
          setState(() {
            _hataMesaji = 'Pusula hatası: $hata';
          });
        },
      );
    } else {
      setState(() {
        _hataMesaji = 'Bu cihazda pusula sensörü bulunmuyor';
      });
    }
  }

  void _kibleHizasiniKontrolEt() {
    double kibleAcisi = _kibleAcisi;
    // Kıble yönünde ±10 derece tolerans
    _kibleyeYakin = (kibleAcisi <= 10 || kibleAcisi >= 350);
  }

  double _kibleYonunuHesapla(double enlem, double boylam) {
    double dBoylam = (kabeBoylam - boylam) * (math.pi / 180);
    double enlem1 = enlem * (math.pi / 180);
    double enlem2 = kabeEnlem * (math.pi / 180);

    double y = math.sin(dBoylam) * math.cos(enlem2);
    double x = math.cos(enlem1) * math.sin(enlem2) -
        math.sin(enlem1) * math.cos(enlem2) * math.cos(dBoylam);

    double aci = math.atan2(y, x) * (180 / math.pi);
    return (aci + 360) % 360;
  }

  double get _kibleAcisi {
    return (_kibleYonu - _yon + 360) % 360;
  }

  double get _cihazAcisi {
    return (_yon + 360) % 360;
  }

  double get _aciFarki {
    double fark = (_kibleYonu - _yon).abs();
    return fark > 180 ? 360 - fark : fark;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_yukleniyor) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        appBar: _uygulamaCubugunuOlustur(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Pusula hazırlanıyor...',
                style: GoogleFonts.poppins(
                  color: colorScheme.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hataMesaji.isNotEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        appBar: _uygulamaCubugunuOlustur(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _hataMesaji,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _yukleniyor = true;
                    _hataMesaji = '';
                  });
                  _pusulayiBaslat();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Tekrar Dene',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: _uygulamaCubugunuOlustur(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _sensorDurumunuOlustur(),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: _anaPusulayiOlustur(),
              ),
            ),
            _kibleDurumunuOlustur(),
            const SizedBox(height: 24),
            _altBilgiPaneliniOlustur(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _uygulamaCubugunuOlustur() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
      ),
      title: Text(
        'Kıble Pusulası',
        style: GoogleFonts.poppins(
          color: colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => _mevcutKonumuAl(),
          icon: Icon(Icons.my_location, color: colorScheme.onPrimary),
        ),
        IconButton(
          onPressed: _pusulayiBaslat,
          icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
        ),
      ],
    );
  }

  Widget _sensorDurumunuOlustur() {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sensors,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Sensör Aktif',
            style: GoogleFonts.poppins(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _anaPusulayiOlustur() {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animasyonKontrolcusu,
      builder: (context, child) {
        return Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dış gradyan halka
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // İç daire
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface,
                ),
              ),
              // Pusula işaretleri
              Transform.rotate(
                angle: -_yon * (math.pi / 180) * _pusulaAnimasyonu.value,
                child: _pusulaIsaretleriniOlustur(),
              ),
              // Yön etiketleri
              Transform.rotate(
                angle: -_yon * (math.pi / 180) * _pusulaAnimasyonu.value,
                child: _yonEtiketleriniOlustur(),
              ),
              // Kıble göstergesi
              Transform.rotate(
                angle: _kibleAcisi * (math.pi / 180) * _pusulaAnimasyonu.value,
                child: _kibleGostergesiniOlustur(),
              ),
              // Merkez nokta
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pusulaIsaretleriniOlustur() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        children: List.generate(36, (index) {
          final aci = index * 10.0;
          final anaIsaret = aci % 90 == 0;

          return Transform.rotate(
            angle: aci * (math.pi / 180),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: anaIsaret ? 4 : 2,
                height: anaIsaret ? 24 : 12,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _yonEtiketleriniOlustur() {
    final colorScheme = Theme.of(context).colorScheme;
    final yonler = [
      {'aci': 0.0, 'etiket': 'K'},
      {'aci': 90.0, 'etiket': 'D'},
      {'aci': 180.0, 'etiket': 'G'},
      {'aci': 270.0, 'etiket': 'B'},
    ];

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        children: yonler.map((yon) {
          final aci = yon['aci'] as double;
          final etiket = yon['etiket'] as String;

          return Transform.rotate(
            angle: aci * (math.pi / 180),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  etiket,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _kibleGostergesiniOlustur() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            'KIBLE',
            style: GoogleFonts.poppins(
              color: colorScheme.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 0,
          height: 0,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(width: 8, color: Colors.transparent),
              right: BorderSide(width: 8, color: Colors.transparent),
              bottom: BorderSide(width: 12, color: colorScheme.secondary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_upward,
            color: colorScheme.onPrimary,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _kibleDurumunuOlustur() {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kibleyeYakin ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kibleyeYakin ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _kibleyeYakin ? Icons.check_circle : Icons.info,
            color: _kibleyeYakin ? colorScheme.primary : colorScheme.secondary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _kibleyeYakin ? 'KIBLE YÖNÜNE HIZALI!' : 'Kıble yönünü bulun',
              style: GoogleFonts.poppins(
                color: _kibleyeYakin ? colorScheme.primary : colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _altBilgiPaneliniOlustur() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bilgiSutunuOlustur('Cihaz', '${_cihazAcisi.round()}°', colorScheme.primary),
          _bilgiSutunuOlustur('Kıble', '${_kibleYonu.round()}°', colorScheme.primary),
          _bilgiSutunuOlustur('Fark', '${_aciFarki.round()}°', colorScheme.secondary),
        ],
      ),
    );
  }

  Widget _bilgiSutunuOlustur(String etiket, String deger, Color renk) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiket,
          style: GoogleFonts.poppins(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          deger,
          style: GoogleFonts.poppins(
            color: renk,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}