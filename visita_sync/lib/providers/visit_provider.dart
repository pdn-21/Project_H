import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/visit_model.dart';
import '../models/database_settings.dart';
import '../services/database_service.dart';
import '../services/nhso_api_service.dart';
import '../services/excel_export_service.dart';
import '../config/app_config.dart';

class VisitProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NhsoApiService _apiService = NhsoApiService();
  final ExcelExportService _excelService = ExcelExportService();
  final AppConfig _config = AppConfig();

  List<VisitModel> _visits = [];
  bool _isLoading = false;
  bool _isLocalDbConnected = false;
  bool _isSourceDbConnected = false;
  bool _isNhsoApiConnected = false;
  String? _errorMessage;
  int _syncProgress = 0;
  int _syncTotal = 0;

  // Getters
  List<VisitModel> get visits => _visits;
  bool get isLoading => _isLoading;
  bool get isLocalDbConnected => _isLocalDbConnected;
  bool get isSourceDbConnected => _isSourceDbConnected;
  bool get isNhsoApiConnected => _isNhsoApiConnected;
  String? get errorMessage => _errorMessage;
  AppConfig get config => _config;
  DatabaseSettings get currentSettings => _config.settings;
  int get syncProgress => _syncProgress;
  int get syncTotal => _syncTotal;
  double get syncPercentage =>
      _syncTotal > 0 ? (_syncProgress / _syncTotal) : 0;

  /// Initialize Provider
  Future<void> initialize() async {
    await _config.initialize();

    if (_config.hasSettings) {
      final settings = _config.settings;
      _dbService.setSettings(settings);
      _apiService.setSettings(settings);

      await connectDatabases();
      await testNhsoConnection();
    }
  }

  /// เชื่อมต่อฐานข้อมูล
  Future<void> connectDatabases() async {
    try {
      _isLocalDbConnected = await _dbService.connectLocalDatabase();
      _isSourceDbConnected = await _dbService.connectSourceDatabase();

      if (_isLocalDbConnected) {
        await _dbService.createVisitListTable();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Database connection error: $e';
      notifyListeners();
    }
  }

  /// ทดสอบการเชื่อมต่อ NHSO API
  Future<Map<String, dynamic>> testNhsoConnection() async {
    try {
      final result = await _apiService.testConnection();
      _isNhsoApiConnected = result['success'] ?? false;

      if (!result['success']) {
        _errorMessage = '${result['message']}\n${result['details']}';
      } else {
        _errorMessage = null;
      }

      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'NHSO API connection error: $e';
      _isNhsoApiConnected = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาด',
        'details': e.toString(),
      };
    }
  }

  /// ซิงค์ข้อมูลจาก HOSXP
  Future<void> syncData(String fromDate, String toDate) async {
    _isLoading = true;
    _errorMessage = null;
    _syncProgress = 0;
    _syncTotal = 0;
    notifyListeners();

    try {
      print('🔄 Starting data sync...');

      _visits = await _dbService.syncVisitsFromSource(
        fromDate,
        toDate,
      );

      _errorMessage = null;
      print('✅ Sync completed: ${_visits.length} records');
    } on TimeoutException catch (e) {
      _errorMessage = 'หมดเวลาในการซิงค์ข้อมูล\n'
          'กรุณาลองใช้ช่วงวันที่ที่สั้นกว่า\n'
          'หรือตรวจสอบการเชื่อมต่อ Database';
      _visits = [];
      print('❌ Sync timeout: $e');
    } catch (e) {
      _errorMessage = 'Sync error: $e';
      _visits = [];
      print('❌ Sync error: $e');
    } finally {
      _isLoading = false;
      _syncProgress = 0;
      _syncTotal = 0;
      notifyListeners();
    }
  }

  /// โหลดข้อมูลจาก Local Database
  Future<void> loadVisits(String fromDate, String toDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _visits = await _dbService.getVisits(fromDate, toDate);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Load error: $e';
      _visits = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ตรวจสอบ Authen Status จาก NHSO
  Future<void> checkAuthenStatus(String fromDate, String toDate) async {
    if (!_isNhsoApiConnected) {
      _errorMessage = 'NHSO API not connected';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final visitsWithoutEndpoint = _visits
          .where((v) => v.endpoint == null || v.endpoint!.isEmpty)
          .toList();

      int updated = 0;

      for (var visit in visitsWithoutEndpoint) {
        // Format วันที่ให้เป็น yyyy-MM-dd
        String formattedDate = visit.vstdate;

        // ถ้า vstdate มี timestamp ให้ตัดออก
        if (formattedDate.contains(' ')) {
          formattedDate = formattedDate.substring(0, 10);
        }

        print(
            '📝 Checking VN: ${visit.vn}, CID: ${visit.cid}, Date: $formattedDate');

        final claimCode = await _apiService.checkAuthenStatus(
          visit.cid,
          formattedDate, // ส่งวันที่ที่ format แล้ว
        );

        if (claimCode != null) {
          await _dbService.updateEndpoint(visit.vn, claimCode);
          updated++;
          print('✅ Updated VN: ${visit.vn} with Claim Code: $claimCode');
        }

        // Delay เพื่อไม่ให้ API ถูก rate limit
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Reload data
      await loadVisits(fromDate, toDate);

      _errorMessage = 'อัปเดต Claim Code สำเร็จ $updated รายการ';
      print('🎉 Updated $updated claim codes');
    } catch (e) {
      _errorMessage = 'Authen check error: $e';
      print('❌ Authen check error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ส่งออก Excel
  Future<bool> exportToExcel() async {
    try {
      return await _excelService.exportToExcel(_visits);
    } catch (e) {
      _errorMessage = 'Export error: $e';
      notifyListeners();
      return false;
    }
  }

  /// อัปเดตการตั้งค่า
  Future<bool> updateSettings(DatabaseSettings settings) async {
    try {
      print('🔧 Updating settings...');
      print('   Local Host: ${settings.localHost}');
      print('   Source Host: ${settings.sourceHost}');
      print('   NHSO URL: ${settings.nhsoApiUrl}');
      print('   Has Token: ${settings.nhsoAccessToken.isNotEmpty}');

      final saved = await _config.saveSettings(settings);

      if (saved) {
        print('✅ Settings saved to config');

        _dbService.setSettings(settings);
        print('✅ Database service updated');

        _apiService.setSettings(settings);
        print('✅ API service updated');

        await connectDatabases();
        print('✅ Database connection attempted');

        await testNhsoConnection();
        print('✅ NHSO connection tested');

        print('🎉 All settings updated successfully');
        return true;
      } else {
        print('❌ Failed to save settings to config');
        _errorMessage = 'ไม่สามารถบันทึกไฟล์ config ได้';
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Settings update error: $e');
      print('   Stack trace: $stackTrace');
      _errorMessage = 'Settings update error: $e';
      notifyListeners();
      return false;
    }
  }

  /// ทดสอบการเชื่อมต่อฐานข้อมูล
  Future<Map<String, bool>> testConnections(DatabaseSettings settings) async {
    final results = <String, bool>{};

    results['local'] = await _dbService.testLocalConnection(settings);
    results['source'] = await _dbService.testSourceConnection(settings);

    _apiService.setSettings(settings);
    final nhsoResult = await _apiService.testConnection();
    results['nhso'] = nhsoResult['success'] ?? false;

    // เก็บ error message จาก NHSO
    if (!results['nhso']!) {
      _errorMessage = '${nhsoResult['message']}\n${nhsoResult['details']}';
      notifyListeners();
    }

    return results;
  }

  /// ล้างข้อมูล
  void clearData() {
    _visits = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Dispose
  @override
  void dispose() {
    _dbService.close();
    super.dispose();
  }
}
