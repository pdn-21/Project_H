import 'package:dio/dio.dart';
import '../models/database_settings.dart';

class NhsoApiService {
  late Dio _dio;
  DatabaseSettings? _settings;
  bool _isConnected = false;

  NhsoApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  /// ตั้งค่า API settings
  void setSettings(DatabaseSettings settings) {
    _settings = settings;
    _dio.options.headers = {
      _settings!.nhsoTokenHeader: 'Bearer ${_settings!.nhsoAccessToken}',
      'Accept': 'application/json',
    };
  }

  /// ทดสอบการเชื่อมต่อ API
  Future<bool> testConnection() async {
    if (_settings == null || _settings!.nhsoAccessToken.isEmpty) {
      return false;
    }

    try {
      final response = await _dio.get(
        _settings!.nhsoApiUrl,
        queryParameters: {
          'personalId': '1234567890123', // Test CID
          'serviceDate': DateTime.now().toString().substring(0, 10),
        },
      );

      _isConnected = response.statusCode == 200;
      return _isConnected;
    } catch (e) {
      print('❌ NHSO API test failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// ตรวจสอบสถานะ Authen Code
  Future<String?> checkAuthenStatus(
      String personalId, String serviceDate) async {
    if (_settings == null) return null;

    try {
      final response = await _dio.get(
        _settings!.nhsoApiUrl,
        queryParameters: {
          'personalId': personalId,
          'serviceDate': serviceDate,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // ดึง Claim Code จาก response
        if (data['serviceHistories'] != null &&
            data['serviceHistories'].isNotEmpty) {
          final claimCode = data['serviceHistories'][0]['claimCode'];
          return claimCode?.toString();
        }
      }
    } catch (e) {
      if (e is DioException) {
        print('❌ NHSO API Error: ${e.response?.statusCode} - ${e.message}');
      } else {
        print('❌ NHSO API Error: $e');
      }
    }

    return null;
  }

  /// ตรวจสอบ Authen Code หลายรายการ
  Future<Map<String, String>> checkMultipleAuthen(
    List<Map<String, String>> records,
  ) async {
    final results = <String, String>{};

    for (var record in records) {
      final vn = record['vn']!;
      final cid = record['cid']!;
      final date = record['date']!;

      final claimCode = await checkAuthenStatus(cid, date);

      if (claimCode != null) {
        results[vn] = claimCode;
      }

      // Delay เพื่อไม่ให้ request มากเกินไป
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }

  /// ตรวจสอบสถานะการเชื่อมต่อ
  bool get isConnected => _isConnected;

  /// อัปเดตสถานะการเชื่อมต่อ
  set isConnected(bool value) => _isConnected = value;
}
