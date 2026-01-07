import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/visit_model.dart';

class ExcelExportService {
  /// ส่งออกข้อมูลเป็น Excel
  Future<bool> exportToExcel(List<VisitModel> visits) async {
    try {
      // เลือกที่เก็บไฟล์
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return false;

      // สร้างไฟล์ Excel
      final excel = Excel.createExcel();
      final sheet = excel['Visit Data'];

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

      // เขียน Header
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // เขียนข้อมูล
      for (var i = 0; i < visits.length; i++) {
        final visit = visits[i];
        final rowIndex = i + 1;

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
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
        }
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15.0);
      }

      // บันทึกไฟล์
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Visit_Data_$timestamp.xlsx';
      final filePath = '$directory/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      print('✅ Export successful: $filePath');
      return true;
    } catch (e) {
      print('❌ Export error: $e');
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
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return false;

      final excel = Excel.createExcel();
      final sheet = excel['Visit Data'];

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

      // เขียน Header
      for (var i = 0; i < columns.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(columns[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // เขียนข้อมูล (ปรับตามคอลัมน์ที่เลือก)
      for (var i = 0; i < visits.length; i++) {
        final visit = visits[i];
        final rowIndex = i + 1;

        final cell0 = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        cell0.value = TextCellValue(visit.vn);

        if (columns.length > 1) {
          final cell1 = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
          cell1.value = TextCellValue(visit.vstdate);
        }

        if (columns.length > 2) {
          final cell2 = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
          cell2.value = TextCellValue(visit.name);
        }

        // เพิ่ม columns อื่นๆ ตามต้องการ
      }

      // บันทึกไฟล์
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = filename ?? 'Visit_Data_$timestamp.xlsx';
      final filePath = '$directory/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return true;
    } catch (e) {
      print('❌ Export error: $e');
      return false;
    }
  }
}
