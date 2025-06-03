import 'dart:convert';
import 'package:http/http.dart' as http;

class PrayerTimeService {
  final String _baseUrl = 'https://api.aladhan.com/v1';

  Future<Map<String, String>> fetchPrayerTimesForDate({
    required DateTime date,
    String city = 'Istanbul',
    String country = 'Turkey',
    int method = 13,
  }) async {
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final url = Uri.parse(
      '$_baseUrl/timingsByCity/$formattedDate?city=$city&country=$country&method=$method',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data']['timings'];
      return {
        'Fajr': data['Fajr'],
        'Dhuhr': data['Dhuhr'],
        'Asr': data['Asr'],
        'Maghrib': data['Maghrib'],
        'Isha': data['Isha'],
      };
    } else {
      throw Exception('Namaz vakitleri alınamadı: ${response.statusCode}');
    }
  }

  fetchPrayerTimes({required double latitude, required double longitude, required int timezoneOffset}) {}
}
