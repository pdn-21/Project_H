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
      validateStatus: (status) {
        // ยอมรับ status code ทั้งหมดเพื่อดู response
        return status != null && status < 500;
      },
    ));

    // เพิ่ม interceptor เพื่อ debug
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🔵 Request: ${options.method} ${options.uri}');
        print('🔵 Headers: ${options.headers}');
        print('🔵 Query: ${options.queryParameters}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('🟢 Response: ${response.statusCode}');
        print('🟢 Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('🔴 Error: ${error.message}');
        print('🔴 Response: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  /// ตั้งค่า API settings
  void setSettings(DatabaseSettings settings) {
    _settings = settings;

    // ตั้งค่า headers
    final token = settings.nhsoAccessToken.trim();

    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // เพิ่ม Authorization header
    if (token.isNotEmpty) {
      // ตรวจสอบว่ามี Bearer prefix หรือไม่
      if (token.toLowerCase().startsWith('bearer ')) {
        _dio.options.headers[settings.nhsoTokenHeader] = token;
      } else {
        _dio.options.headers[settings.nhsoTokenHeader] = 'Bearer $token';
      }
    }

    print('🔧 API Settings Updated:');
    print('   URL: ${settings.nhsoApiUrl}');
    print('   Token Header: ${settings.nhsoTokenHeader}');
    print('   Has Token: ${token.isNotEmpty}');
  }

  /// ทดสอบการเชื่อมต่อ API (แบบง่าย)
  Future<Map<String, dynamic>> testConnection() async {
    if (_settings == null || _settings!.nhsoAccessToken.isEmpty) {
      return {
        'success': false,
        'message': 'กรุณากรอก API Token',
        'details': 'API Token is required'
      };
    }

    try {
      print('🧪 Testing NHSO API Connection...');

      // ใช้เลขบัตรทดสอบ (13 หลัก)
      final testCID = '1321200075612';

      // Format วันที่เป็น yyyy-MM-dd
      final now = DateTime.now();
      final testDate = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      print('   Test Date: $testDate');

      final response = await _dio.get(
        _settings!.nhsoApiUrl,
        queryParameters: {
          'personalId': testCID,
          'serviceDate': testDate,
        },
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📊 Response Data: ${response.data}');

      // ตรวจสอบ response
      if (response.statusCode == 200) {
        _isConnected = true;
        return {
          'success': true,
          'message': 'เชื่อมต่อ NHSO API สำเร็จ',
          'details': 'Status: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        _isConnected = false;
        return {
          'success': false,
          'message': 'Token ไม่ถูกต้อง (Unauthorized)',
          'details': 'กรุณาตรวจสอบ API Token',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 404) {
        // 404 อาจหมายถึงไม่พบข้อมูลสำหรับเลขบัตรทดสอบ แต่ API ทำงาน
        _isConnected = true;
        return {
          'success': true,
          'message': 'เชื่อมต่อสำเร็จ (ไม่พบข้อมูลทดสอบ)',
          'details': 'API endpoint is reachable',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 400) {
        // Bad Request - อาจเป็นปัญหาจาก parameter
        _isConnected = false;
        final errorData = response.data;
        String details = 'Status Code: 400';

        if (errorData is Map && errorData['errors'] != null) {
          final errors = errorData['errors'] as List;
          if (errors.isNotEmpty) {
            details = errors[0]['defaultMessage'] ?? details;
          }
        }

        return {
          'success': false,
          'message': 'Bad Request',
          'details': details,
          'statusCode': response.statusCode,
        };
      } else {
        _isConnected = false;
        return {
          'success': false,
          'message': 'เชื่อมต่อไม่สำเร็จ',
          'details': 'Status Code: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      _isConnected = false;

      print('🔴 DioException: ${e.type}');
      print('🔴 Message: ${e.message}');
      print('🔴 Response: ${e.response?.data}');

      String message = 'เชื่อมต่อไม่สำเร็จ';
      String details = '';

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          message = 'หมดเวลาในการเชื่อมต่อ';
          details = 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'หมดเวลารอรับข้อมูล';
          details = 'Server ตอบสนองช้า';
          break;
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          message = 'เซิร์ฟเวอร์ตอบกลับผิดพลาด';
          details = 'Status Code: $statusCode';

          if (statusCode == 401) {
            message = 'Token ไม่ถูกต้อง';
            details = 'กรุณาตรวจสอบ API Token ใหม่';
          } else if (statusCode == 403) {
            message = 'ไม่มีสิทธิ์เข้าถึง';
            details = 'Token อาจหมดอายุหรือไม่มีสิทธิ์';
          }
          break;
        case DioExceptionType.connectionError:
          message = 'ไม่สามารถเชื่อมต่อได้';
          details = 'ตรวจสอบ URL หรือการเชื่อมต่ออินเทอร์เน็ต';
          break;
        default:
          message = 'เกิดข้อผิดพลาด';
          details = e.message ?? 'Unknown error';
      }

      return {
        'success': false,
        'message': message,
        'details': details,
        'error': e.message,
      };
    } catch (e) {
      _isConnected = false;
      print('🔴 Unexpected Error: $e');

      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดที่ไม่คาดคิด',
        'details': e.toString(),
      };
    }
  }

  /// ตรวจสอบสถานะ Authen Code
  Future<String?> checkAuthenStatus(
      String personalId, String serviceDate) async {
    if (_settings == null) return null;

    try {
      // แปลงรูปแบบวันที่ให้ถูกต้อง (yyyy-MM-dd)
      String formattedDate = serviceDate;

      // ถ้ามี timestamp หรือ time zone ให้ตัดออก
      if (serviceDate.contains(' ') || serviceDate.contains('T')) {
        try {
          final date = DateTime.parse(serviceDate);
          formattedDate = '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          // ถ้า parse ไม่ได้ ให้ใช้แบบ substring
          formattedDate = serviceDate.substring(0, 10);
        }
      }

      print('🔍 Checking Authen: CID=$personalId, Date=$formattedDate');

      final response = await _dio.get(
        _settings!.nhsoApiUrl,
        queryParameters: {
          'personalId': personalId,
          'serviceDate': formattedDate, // ใช้วันที่ที่ format แล้ว
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        print('📋 Response Data: $data');

        // ดึง Claim Code จาก response
        if (data is Map<String, dynamic>) {
          if (data['serviceHistories'] != null &&
              data['serviceHistories'] is List &&
              (data['serviceHistories'] as List).isNotEmpty) {
            final firstHistory = data['serviceHistories'][0];
            final claimCode = firstHistory['claimCode'];

            print('✅ Found Claim Code: $claimCode');
            return claimCode?.toString();
          }
        }

        print('⚠️  No claim code found in response');
      } else if (response.statusCode == 400) {
        print('⚠️  Bad Request (400): ${response.data}');
        print('   Check date format: $formattedDate');
      } else {
        print('⚠️  Response status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        print('❌ NHSO API Error: ${e.response?.statusCode} - ${e.message}');
        print('   Response: ${e.response?.data}');
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

      print('📝 Processing VN: $vn');

      final claimCode = await checkAuthenStatus(cid, date);

      if (claimCode != null) {
        results[vn] = claimCode;
        print('✅ VN: $vn => Claim Code: $claimCode');
      } else {
        print('⚠️  VN: $vn => No claim code found');
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

  /// ดึงข้อมูล settings ปัจจุบัน
  DatabaseSettings? get currentSettings => _settings;
}
