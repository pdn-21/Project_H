import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/database_settings.dart';
import '../services/encryption_service.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  final EncryptionService _encryption = EncryptionService();
  DatabaseSettings? _settings;
  String? _configPath;

  /// Initialize config
  Future<void> initialize() async {
    _encryption.initialize();
    
    final directory = await getApplicationDocumentsDirectory();
    final configDir = Directory('${directory.path}/hospital_visit_config');
    
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    
    _configPath = '${configDir.path}/config.enc';
    await loadSettings();
  }

  /// โหลดการตั้งค่า
  Future<void> loadSettings() async {
    try {
      if (_configPath == null) return;
      
      final file = File(_configPath!);
      
      if (await file.exists()) {
        final encryptedData = await file.readAsString();
        final decryptedData = _encryption.decryptJson(encryptedData);
        
        if (decryptedData.isNotEmpty) {
          _settings = DatabaseSettings.fromJson(decryptedData);
          print('✅ Settings loaded successfully');
        } else {
          _settings = DatabaseSettings();
        }
      } else {
        _settings = DatabaseSettings();
        print('ℹ️ No config file found, using defaults');
      }
    } catch (e) {
      print('❌ Error loading settings: $e');
      _settings = DatabaseSettings();
    }
  }

  /// บันทึกการตั้งค่า
  Future<bool> saveSettings(DatabaseSettings settings) async {
    try {
      if (_configPath == null) return false;
      
      _settings = settings;
      
      final jsonData = settings.toJson();
      final encryptedData = _encryption.encryptJson(jsonData);
      
      final file = File(_configPath!);
      await file.writeAsString(encryptedData);
      
      print('✅ Settings saved successfully');
      return true;
    } catch (e) {
      print('❌ Error saving settings: $e');
      return false;
    }
  }

  /// ดึงการตั้งค่าปัจจุบัน
  DatabaseSettings get settings => _settings ?? DatabaseSettings();

  /// ตรวจสอบว่ามีการตั้งค่าหรือไม่
  bool get hasSettings => _settings != null;

  /// ล้างการตั้งค่า
  Future<void> clearSettings() async {
    try {
      if (_configPath == null) return;
      
      final file = File(_configPath!);
      if (await file.exists()) {
        await file.delete();
      }
      
      _settings = DatabaseSettings();
      print('✅ Settings cleared');
    } catch (e) {
      print('❌ Error clearing settings: $e');
    }
  }

  /// Export การตั้งค่าแบบ plain text (สำหรับ backup)
  Future<String?> exportSettings() async {
    try {
      if (_settings == null) return null;
      
      final jsonData = _settings!.toJson();
      return json.encode(jsonData);
    } catch (e) {
      print('❌ Error exporting settings: $e');
      return null;
    }
  }

  /// Import การตั้งค่าจาก plain text
  Future<bool> importSettings(String jsonString) async {
    try {
      final jsonData = json.decode(jsonString);
      final settings = DatabaseSettings.fromJson(jsonData);
      return await saveSettings(settings);
    } catch (e) {
      print('❌ Error importing settings: $e');
      return false;
    }
  }
}