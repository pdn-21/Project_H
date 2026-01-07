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

  // Getters
  List<VisitModel> get visits => _visits;
  bool get isLoading => _isLoading;
  bool get isLocalDbConnected => _isLocalDbConnected;
  bool get isSourceDbConnected => _isSourceDbConnected;
  bool get isNhsoApiConnected => _isNhsoApiConnected;
  String? get errorMessage => _errorMessage;
  AppConfig get config => _config;
  DatabaseSettings get currentSettings => _config.settings;

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
  Future<void> testNhsoConnection() async {
    try {
      _isNhsoApiConnected = await _apiService.testConnection();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'NHSO API connection error: $e';
      notifyListeners();
    }
  }

  /// ซิงค์ข้อมูลจาก HOSXP
  Future<void> syncData(String fromDate, String toDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _visits = await _dbService.syncVisitsFromSource(fromDate, toDate);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Sync error: $e';
      _visits = [];
    } finally {
      _isLoading = false;
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
        final claimCode = await _apiService.checkAuthenStatus(
          visit.cid,
          visit.vstdate,
        );

        if (claimCode != null) {
          await _dbService.updateEndpoint(visit.vn, claimCode);
          updated++;
        }

        // Delay เพื่อไม่ให้ API ถูก rate limit
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Reload data
      await loadVisits(fromDate, toDate);

      _errorMessage = 'Updated $updated claim codes';
    } catch (e) {
      _errorMessage = 'Authen check error: $e';
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
      final saved = await _config.saveSettings(settings);

      if (saved) {
        _dbService.setSettings(settings);
        _apiService.setSettings(settings);
        await connectDatabases();
        await testNhsoConnection();
      }

      return saved;
    } catch (e) {
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
    results['nhso'] = await _apiService.testConnection();

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
