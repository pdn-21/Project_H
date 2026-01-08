import 'dart:async';
import 'package:mysql1/mysql1.dart';
import '../models/visit_model.dart';
import '../models/database_settings.dart';

class DatabaseService {
  MySqlConnection? _localConnection;
  MySqlConnection? _sourceConnection;
  DatabaseSettings? _settings;

  /// ตั้งค่า database settings
  void setSettings(DatabaseSettings settings) {
    _settings = settings;
  }

  /// เชื่อมต่อ Local Database (MariaDB)
  Future<bool> connectLocalDatabase() async {
    try {
      if (_settings == null) {
        print('❌ Settings is null');
        return false;
      }

      print('🔌 Connecting to Local Database...');
      print('   Host: ${_settings!.localHost}:${_settings!.localPort}');
      print('   Database: ${_settings!.localDatabase}');
      print('   User: ${_settings!.localUsername}');

      final settings = ConnectionSettings(
        host: _settings!.localHost,
        port: _settings!.localPort,
        user: _settings!.localUsername,
        password: _settings!.localPassword,
        db: _settings!.localDatabase,
        timeout: const Duration(seconds: 30), // เพิ่ม timeout
      );

      _localConnection = await MySqlConnection.connect(settings).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ Local database connection timeout');
          throw TimeoutException('Connection timeout');
        },
      );

      print('✅ Connected to Local Database');
      return true;
    } on TimeoutException catch (e) {
      print('❌ Local Database connection timeout: $e');
      print('   กรุณาตรวจสอบ:');
      print('   1. MariaDB กำลังทำงานอยู่หรือไม่');
      print('   2. Host และ Port ถูกต้องหรือไม่');
      print('   3. Firewall อนุญาตการเชื่อมต่อหรือไม่');
      return false;
    } catch (e) {
      print('❌ Local Database connection failed: $e');
      return false;
    }
  }

  /// เชื่อมต่อ Source Database (HOSXP)
  Future<bool> connectSourceDatabase() async {
    try {
      if (_settings == null) {
        print('❌ Settings is null');
        return false;
      }

      print('🔌 Connecting to Source Database...');
      print('   Host: ${_settings!.sourceHost}:${_settings!.sourcePort}');
      print('   Database: ${_settings!.sourceDatabase}');
      print('   User: ${_settings!.sourceUsername}');

      final settings = ConnectionSettings(
        host: _settings!.sourceHost,
        port: _settings!.sourcePort,
        user: _settings!.sourceUsername,
        password: _settings!.sourcePassword,
        db: _settings!.sourceDatabase,
        timeout: const Duration(seconds: 30),
      );

      _sourceConnection = await MySqlConnection.connect(settings).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ Source database connection timeout');
          throw TimeoutException('Connection timeout');
        },
      );

      print('✅ Connected to Source Database');
      return true;
    } on TimeoutException catch (e) {
      print('❌ Source Database connection timeout: $e');
      print('   กรุณาตรวจสอบ:');
      print('   1. HOSXP Server กำลังทำงานอยู่หรือไม่');
      print('   2. Network สามารถเชื่อมต่อได้หรือไม่');
      print('   3. Username/Password ถูกต้องหรือไม่');
      return false;
    } catch (e) {
      print('❌ Source Database connection failed: $e');
      return false;
    }
  }

  /// ทดสอบการเชื่อมต่อ Local Database
  Future<bool> testLocalConnection(DatabaseSettings settings) async {
    try {
      final connSettings = ConnectionSettings(
        host: settings.localHost,
        port: settings.localPort,
        user: settings.localUsername,
        password: settings.localPassword,
        db: settings.localDatabase,
        timeout: const Duration(seconds: 5),
      );

      final conn = await MySqlConnection.connect(connSettings);
      await conn.close();
      return true;
    } catch (e) {
      print('Test connection failed: $e');
      return false;
    }
  }

  /// ทดสอบการเชื่อมต่อ Source Database
  Future<bool> testSourceConnection(DatabaseSettings settings) async {
    try {
      final connSettings = ConnectionSettings(
        host: settings.sourceHost,
        port: settings.sourcePort,
        user: settings.sourceUsername,
        password: settings.sourcePassword,
        db: settings.sourceDatabase,
        timeout: const Duration(seconds: 5),
      );

      final conn = await MySqlConnection.connect(connSettings);
      await conn.close();
      return true;
    } catch (e) {
      print('Test connection failed: $e');
      return false;
    }
  }

  /// สร้างตาราง visit_list ใน Local Database
  Future<void> createVisitListTable() async {
    if (_localConnection == null) return;

    const createTableQuery = '''
      CREATE TABLE IF NOT EXISTS visit_list (
        id INT AUTO_INCREMENT PRIMARY KEY,
        vn VARCHAR(20) NOT NULL,
        vstdate DATE NOT NULL,
        hn VARCHAR(20),
        name VARCHAR(255),
        cid VARCHAR(13),
        pttypename VARCHAR(100),
        pttype VARCHAR(10),
        department VARCHAR(100),
        auth_code VARCHAR(50),
        close_seq VARCHAR(50),
        close_staff VARCHAR(100),
        income DECIMAL(10,2) DEFAULT 0,
        uc_money DECIMAL(10,2) DEFAULT 0,
        paid_money DECIMAL(10,2) DEFAULT 0,
        arrearage DECIMAL(10,2) DEFAULT 0,
        outdepcode VARCHAR(100),
        vsttime TIME,
        ovstost VARCHAR(10),
        endpoint VARCHAR(50),
        close_visit CHAR(1),
        date VARCHAR(10),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_vn_vstdate (vn, vstdate),
        INDEX idx_vstdate (vstdate),
        INDEX idx_cid (cid),
        INDEX idx_endpoint (endpoint)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ''';

    try {
      await _localConnection!.query(createTableQuery);
      print('✅ Table visit_list created or already exists');
    } catch (e) {
      print('❌ Error creating table: $e');
    }
  }

  /// ซิงค์ข้อมูลจาก Source Database
  Future<List<VisitModel>> syncVisitsFromSource(
      String fromDate, String toDate) async {
    if (_sourceConnection == null || _localConnection == null) {
      throw Exception('Database connections not established');
    }

    final visits = <VisitModel>[];

    try {
      // Query จาก Source Database (HOSXP)
      final results = await _sourceConnection!.query('''
        SELECT 
          (SELECT IF(vn IS NOT NULL, 'Y', 'N') FROM nhso_confirm_privilege WHERE vn = v.vn LIMIT 1) AS close_visit,
          v.vn, v.vstdate, v.hn, CONCAT(pt.pname, pt.fname, '  ', pt.lname) AS name, pt.cid,
          v.income, v.pttype, p.name AS pttypename, k.department, vp.auth_code,
          (SELECT nhso_seq FROM nhso_confirm_privilege WHERE vn = v.vn LIMIT 1) AS close_seq,
          (SELECT d.name FROM nhso_confirm_privilege x 
           LEFT JOIN doctor d ON d.code = x.confirm_staff 
           WHERE x.vn = v.vn LIMIT 1) AS close_staff,
          o.vsttime, o.ovstost
        FROM vn_stat v
        LEFT JOIN patient pt ON pt.cid = v.cid
        LEFT JOIN ovst o ON o.vn = v.vn
        LEFT JOIN pttype p ON p.pttype = v.pttype
        LEFT JOIN kskdepartment k ON k.depcode = o.main_dep
        LEFT JOIN visit_pttype vp ON vp.vn = v.vn
        WHERE v.vstdate BETWEEN ? AND ?
        ORDER BY v.vn ASC
      ''', [fromDate, toDate]);

      // บันทึกลง Local Database
      for (var row in results) {
        final visit = VisitModel(
          vn: row['vn']?.toString() ?? '',
          vstdate: row['vstdate']?.toString() ?? '',
          hn: row['hn']?.toString() ?? '',
          name: row['name']?.toString() ?? '',
          cid: row['cid']?.toString() ?? '',
          pttypename: row['pttypename']?.toString(),
          pttype: row['pttype']?.toString(),
          department: row['department']?.toString(),
          authCode: row['auth_code']?.toString(),
          closeSeq: row['close_seq']?.toString(),
          closeStaff: row['close_staff']?.toString(),
          income: double.tryParse(row['income']?.toString() ?? '0') ?? 0,
          vsttime: row['vsttime']?.toString(),
          ovstost: row['ovstost']?.toString(),
          closeVisit: row['close_visit']?.toString(),
        );

        await saveVisit(visit);
        visits.add(visit);
      }

      print('✅ Synced ${visits.length} visits');
    } catch (e) {
      print('❌ Sync error: $e');
    }

    return visits;
  }

  /// บันทึกข้อมูล visit ลง Local Database
  Future<void> saveVisit(VisitModel visit) async {
    if (_localConnection == null) return;

    try {
      await _localConnection!.query('''
        INSERT INTO visit_list (
          vn, vstdate, hn, name, cid, pttypename, pttype, department, 
          auth_code, close_seq, close_staff, income, uc_money, paid_money, 
          arrearage, outdepcode, vsttime, ovstost, endpoint, close_visit, date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          name = VALUES(name),
          pttypename = VALUES(pttypename),
          pttype = VALUES(pttype),
          department = VALUES(department),
          income = VALUES(income),
          uc_money = VALUES(uc_money),
          paid_money = VALUES(paid_money),
          endpoint = VALUES(endpoint)
      ''', [
        visit.vn,
        visit.vstdate,
        visit.hn,
        visit.name,
        visit.cid,
        visit.pttypename,
        visit.pttype,
        visit.department,
        visit.authCode,
        visit.closeSeq,
        visit.closeStaff,
        visit.income,
        visit.ucMoney,
        visit.paidMoney,
        visit.arrearage,
        visit.outdepcode,
        visit.vsttime,
        visit.ovstost,
        visit.endpoint,
        visit.closeVisit,
        visit.date,
      ]);
    } catch (e) {
      print('❌ Error saving visit: $e');
    }
  }

  /// ดึงข้อมูล visits จาก Local Database
  Future<List<VisitModel>> getVisits(String fromDate, String toDate) async {
    if (_localConnection == null) return [];

    final visits = <VisitModel>[];

    try {
      final results = await _localConnection!.query('''
        SELECT * FROM visit_list 
        WHERE vstdate BETWEEN ? AND ?
        ORDER BY vn DESC
      ''', [fromDate, toDate]);

      for (var row in results) {
        visits.add(VisitModel.fromJson(row.fields));
      }
    } catch (e) {
      print('❌ Error getting visits: $e');
    }

    return visits;
  }

  /// อัปเดต endpoint (Claim Code)
  Future<void> updateEndpoint(String vn, String endpoint) async {
    if (_localConnection == null) return;

    try {
      await _localConnection!.query('''
        UPDATE visit_list SET endpoint = ? WHERE vn = ?
      ''', [endpoint, vn]);
    } catch (e) {
      print('❌ Error updating endpoint: $e');
    }
  }

  /// ตรวจสอบสถานะการเชื่อมต่อ
  bool get isLocalConnected => _localConnection != null;
  bool get isSourceConnected => _sourceConnection != null;

  /// ปิดการเชื่อมต่อ
  Future<void> close() async {
    await _localConnection?.close();
    await _sourceConnection?.close();
    _localConnection = null;
    _sourceConnection = null;
  }
}
