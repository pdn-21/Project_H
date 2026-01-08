import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/visit_model.dart';

class ExcelExportService {
  /// ส่งออกข้อมูลเป็น Excel
  Future<bool> exportToExcel(List<VisitModel> visits) async {
    try {
      print('📊 Starting Excel export...');
      print('   Total records: ${visits.length}');

      if (visits.isEmpty) {
        print('⚠️  No data to export');
        return false;
      }

      // เลือกที่เก็บไฟล์
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) {
        print('❌ User cancelled directory selection');
        return false;
      }

      print('📁 Selected directory: $directory');

      // สร้างไฟล์ Excel
      var excel = Excel.createExcel();

      // ลบ sheet default
      excel.delete('Sheet1');

      // สร้าง sheet ใหม่
      var sheet = excel['Visit Data'];

      print('📝 Creating Excel file...');

      // ตั้งค่า Header Style
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // ตั้งค่า Header
      final headers = [
        'VN',
        'วันที่',
        'HN',
        'ชื่อ-นามสกุล',
        'เลขบัตรประชาชน',
        'รหัสสิทธิ',
        'สิทธิการรักษา',
        'แผนก',
        'แผนกย่อย',
        'เวลา',
        'รายได้',
        'UC Money',
        'Paid Money',
        'ค้างชำระ',
        'Claim Code',
        'สถานะ',
        'Auth Code',
      ];

      print('   Writing headers...');

      // เขียน Header
      for (var i = 0; i < headers.length; i++) {
        var cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      print('   Writing data rows...');

      // เขียนข้อมูล
      for (var i = 0; i < visits.length; i++) {
        final visit = visits[i];
        final rowIndex = i + 1;

        // Debug log ทุก 100 records
        if ((i + 1) % 100 == 0) {
          print('   Progress: ${i + 1}/${visits.length}');
        }

        final rowData = [
          visit.vn,
          visit.vstdate,
          visit.hn,
          visit.name,
          visit.cid,
          visit.pttype ?? '',
          visit.pttypename ?? '',
          visit.department ?? '',
          visit.outdepcode ?? '',
          visit.vsttime ?? '',
          visit.income.toStringAsFixed(2),
          visit.ucMoney.toStringAsFixed(2),
          visit.paidMoney.toStringAsFixed(2),
          visit.arrearage.toStringAsFixed(2),
          visit.endpoint ?? '',
          visit.closeVisit ?? '',
          visit.authCode ?? '',
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
          cell.value = TextCellValue(rowData[j]);

          // Center align สำหรับบางคอลัมน์
          if (j == 0 || j == 1 || j == 5 || j == 15) {
            // VN, วันที่, รหัสสิทธิ, สถานะ
            cell.cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
            );
          }
        }
      }

      print('   Setting column widths...');

      // Auto-fit columns
      final columnWidths = [
        15,
        12,
        10,
        30,
        15,
        10,
        25,
        20,
        15,
        10,
        12,
        12,
        12,
        12,
        15,
        10,
        15
      ];
      for (var i = 0; i < columnWidths.length; i++) {
        sheet.setColumnWidth(i, columnWidths[i].toDouble());
      }

      // บันทึกไฟล์
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Visit_Data_$timestamp.xlsx';
      final filePath = '$directory${Platform.pathSeparator}$fileName';

      print('💾 Saving file: $filePath');

      final fileBytes = excel.encode();

      if (fileBytes == null) {
        print('❌ Failed to encode Excel file');
        return false;
      }

      print('   File size: ${fileBytes.length} bytes');

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Verify file was created
      if (await file.exists()) {
        final savedFileSize = await file.length();
        print('✅ Export successful!');
        print('   Path: $filePath');
        print('   Size: $savedFileSize bytes');
        print('   Records: ${visits.length}');
        return true;
      } else {
        print('❌ File was not created');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Export error: $e');
      print('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// ส่งออกข้อมูลแบบกำหนดเอง
  Future<bool> exportToExcelWithFilter(
    List<VisitModel> visits, {
    String? filename,
    List<String>? selectedColumns,
  }) async {
    try {
      if (visits.isEmpty) {
        print('⚠️  No data to export');
        return false;
      }

      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return false;

      var excel = Excel.createExcel();
      excel.delete('Sheet1');
      var sheet = excel['Visit Data'];

      // กำหนด columns ที่จะส่งออก
      final columns = selectedColumns ??
          [
            'VN',
            'วันที่',
            'ชื่อ-นามสกุล',
            'รหัสสิทธิ',
            'แผนก',
            'รายได้',
            'Claim Code'
          ];

      // Header Style
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );

      // เขียน Header
      for (var i = 0; i < columns.length; i++) {
        var cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(columns[i]);
        cell.cellStyle = headerStyle;
      }

      // เขียนข้อมูล (ปรับตามคอลัมน์ที่เลือก)
      for (var i = 0; i < visits.length; i++) {
        final visit = visits[i];
        final rowIndex = i + 1;

        final rowData = [
          visit.vn,
          visit.vstdate,
          visit.name,
          visit.pttype ?? '',
          visit.department ?? '',
          visit.income.toStringAsFixed(2),
          visit.endpoint ?? '',
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
          cell.value = TextCellValue(rowData[j]);
        }
      }

      // Set column widths
      for (var i = 0; i < columns.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      // บันทึกไฟล์
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = filename ?? 'Visit_Data_$timestamp.xlsx';
      final filePath = '$directory${Platform.pathSeparator}$fileName';

      final fileBytes = excel.encode();
      if (fileBytes == null) return false;

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      print('✅ Custom export successful: $filePath');
      return await file.exists();
    } catch (e) {
      print('❌ Export error: $e');
      return false;
    }
  }
}
