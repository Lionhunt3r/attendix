import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/enums.dart';
import '../../data/models/attendance/attendance.dart';
import '../../data/models/person/person.dart';

/// Export Service for generating PDF and Excel files
///
/// Based on Ionic export.page.ts
class ExportService {
  /// Generate player list PDF
  Future<void> exportPlayerListPdf({
    required BuildContext context,
    required List<Person> players,
    required List<String> fields,
    required String tenantName,
  }) async {
    final date = DateFormat('dd.MM.yyyy').format(DateTime.now());
    final pdf = pw.Document();

    // Prepare data rows
    final data = <List<String>>[];
    int row = 1;

    for (final player in players) {
      data.add([
        row.toString(),
        ...fields.map((f) => _getPlayerFieldValue(player, f)),
      ]);
      row++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            '$tenantName Spielerliste Stand: $date',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['#', ...fields],
            data: data,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF005238), // Dark green
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${tenantName}_Spielerliste_$date.pdf',
    );
  }

  /// Generate player list Excel
  Future<Uint8List> exportPlayerListExcel({
    required List<Person> players,
    required List<String> fields,
    required String tenantName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Spielerliste'];

    // Header row
    sheet.appendRow([
      TextCellValue('#'),
      ...fields.map((f) => TextCellValue(f)),
    ]);

    // Data rows
    int row = 1;
    for (final player in players) {
      sheet.appendRow([
        TextCellValue(row.toString()),
        ...fields.map((f) => TextCellValue(_getPlayerFieldValue(player, f))),
      ]);
      row++;
    }

    // Style header
    for (int i = 0; i <= fields.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#005238'),
        fontColorHex: ExcelColor.white,
      );
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generate attendance list PDF with status codes
  Future<void> exportAttendancePdf({
    required BuildContext context,
    required List<Person> players,
    required List<Attendance> attendances,
    required List<PersonAttendance> personAttendances,
    required List<String> fields,
    required String tenantName,
  }) async {
    final date = DateFormat('dd.MM.yyyy').format(DateTime.now());
    final pdf = pw.Document();

    // Limit to last 8 attendances for PDF
    final limitedAttendances = attendances.length > 8
        ? attendances.sublist(attendances.length - 8)
        : attendances;

    // Prepare attendance dates
    final attDates = limitedAttendances.map((a) {
      final d = DateTime.tryParse(a.date);
      return d != null ? DateFormat('dd.MM').format(d) : '';
    }).toList();

    // Build data rows
    final data = <List<String>>[];
    int row = 1;

    for (final player in players) {
      final attInfo = <String>[];

      for (final att in limitedAttendances) {
        // BL-011: Use firstOrNull - null means "not recorded" which is correct
        final pa = personAttendances
            .where((p) => p.personId == player.id && p.attendanceId == att.id)
            .firstOrNull;
        attInfo.add(_getStatusCode(pa?.status));
      }

      data.add([
        row.toString(),
        ...fields.map((f) => _getPlayerFieldValue(player, f)),
        ...attInfo.reversed,
      ]);
      row++;
    }

    // Headers
    final headers = ['#', ...fields, ...attDates.reversed];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            '$tenantName Anwesenheit Stand: $date',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF005238),
            ),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(2),
            cellDecoration: (index, data, rowNum) {
              if (rowNum == 0 || data == null) return const pw.BoxDecoration();
              return _getStatusCellDecoration(data.toString());
            },
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${tenantName}_Anwesenheit_$date.pdf',
    );
  }

  /// Generate attendance Excel
  Future<Uint8List> exportAttendanceExcel({
    required List<Person> players,
    required List<Attendance> attendances,
    required List<PersonAttendance> personAttendances,
    required List<String> fields,
    required String tenantName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Anwesenheit'];

    // Attendance dates
    final attDates = attendances.map((a) {
      final d = DateTime.tryParse(a.date);
      return d != null ? DateFormat('dd.MM.yy').format(d) : '';
    }).toList();

    // Header row
    sheet.appendRow([
      TextCellValue('#'),
      ...fields.map((f) => TextCellValue(f)),
      ...attDates.reversed.map((d) => TextCellValue(d)),
    ]);

    // Data rows
    int row = 1;
    for (final player in players) {
      final attInfo = <String>[];

      for (final att in attendances) {
        // BL-011: Use firstOrNull - null means "not recorded" which is correct
        final pa = personAttendances
            .where((p) => p.personId == player.id && p.attendanceId == att.id)
            .firstOrNull;
        attInfo.add(_getStatusCode(pa?.status));
      }

      sheet.appendRow([
        TextCellValue(row.toString()),
        ...fields.map((f) => TextCellValue(_getPlayerFieldValue(player, f))),
        ...attInfo.reversed.map((s) => TextCellValue(s)),
      ]);
      row++;
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Get player field value by field name
  String _getPlayerFieldValue(Person player, String field) {
    switch (field) {
      case 'Vorname':
        return player.firstName;
      case 'Nachname':
        return player.lastName;
      case 'Geburtsdatum':
        if (player.birthday != null) {
          final d = DateTime.tryParse(player.birthday!);
          return d != null ? DateFormat('dd.MM.yyyy').format(d) : '';
        }
        return '';
      case 'Gruppe':
        return player.groupName ?? '';
      case 'Email':
        return player.email ?? '';
      case 'Telefon':
        return player.phone ?? '';
      default:
        return '';
    }
  }

  /// Get status code for display
  /// BL-011: Accept nullable status - null means "not recorded"
  String _getStatusCode(AttendanceStatus? status) {
    if (status == null) return '-';
    switch (status) {
      case AttendanceStatus.present:
        return 'X';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.excused:
        return 'E';
      case AttendanceStatus.late:
      case AttendanceStatus.lateExcused:
        return 'L';
      case AttendanceStatus.neutral:
        return 'N';
    }
  }

  /// Get cell decoration based on status code
  pw.BoxDecoration _getStatusCellDecoration(String code) {
    switch (code) {
      case 'X':
        return const pw.BoxDecoration(color: PdfColor.fromInt(0xFF32CD32)); // Green
      case 'A':
        return const pw.BoxDecoration(color: PdfColor.fromInt(0xFFB22222)); // Red
      case 'E':
        return const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFC409)); // Yellow
      case 'L':
        return const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00BFFF)); // Blue
      case 'N':
        return const pw.BoxDecoration(color: PdfColor.fromInt(0xFFDCDCDC)); // Gray
      default:
        return const pw.BoxDecoration();
    }
  }

  /// Generate plan/program PDF
  Future<void> exportPlanPdf({
    required BuildContext context,
    required String tenantName,
    required String date,
    required String startTime,
    required String? endTime,
    required List<Map<String, dynamic>> fields,
  }) async {
    final pdf = pw.Document();

    // Calculate times for each field
    final data = <List<String>>[];
    var currentMinutes = _parseTime(startTime);

    for (final field in fields) {
      final name = field['name'] as String? ?? '';
      final conductor = field['conductor'] as String? ?? '';
      final duration = int.tryParse(field['time']?.toString() ?? '0') ?? 0;

      final formattedTime = _formatMinutes(currentMinutes);
      data.add([formattedTime, name, conductor, '$duration\'']);

      currentMinutes += duration;
    }

    // Add end time row if specified
    if (endTime != null) {
      data.add([endTime, 'Ende', '', '']);
    } else {
      data.add([_formatMinutes(currentMinutes), 'Ende', '', '']);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Text(
              tenantName,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Probenprogramm $date',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.TableHelper.fromTextArray(
              headers: ['Zeit', 'Programm', 'Dirigent', 'Dauer'],
              data: data,
              cellStyle: const pw.TextStyle(fontSize: 11),
              headerStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF005238),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.center,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.all(8),
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(50),
              },
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${tenantName}_Probenprogramm_$date.pdf',
    );
  }

  /// Parse time string "HH:MM" to minutes since midnight
  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  /// Format minutes since midnight to "HH:MM"
  String _formatMinutes(int minutes) {
    final hours = (minutes ~/ 60) % 24;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Export a single attendance to Excel
  /// Shows all persons with their status for this attendance
  Future<void> exportAttendanceToExcel({
    required BuildContext context,
    required Attendance attendance,
    required List<Person> persons,
    required Map<int, AttendanceStatus> statuses,
    required String tenantName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Anwesenheit'];

    // Format attendance date
    final dateObj = DateTime.tryParse(attendance.date);
    final dateStr = dateObj != null
        ? DateFormat('dd.MM.yyyy').format(dateObj)
        : attendance.date;

    // Title row
    sheet.appendRow([
      TextCellValue('$tenantName - Anwesenheit $dateStr'),
    ]);
    sheet.appendRow([]); // Empty row

    // Header row
    sheet.appendRow([
      TextCellValue('#'),
      TextCellValue('Vorname'),
      TextCellValue('Nachname'),
      TextCellValue('Gruppe'),
      TextCellValue('Status'),
    ]);

    // Style header
    for (int i = 0; i < 5; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#005238'),
        fontColorHex: ExcelColor.white,
      );
    }

    // Data rows
    int row = 1;
    for (final person in persons) {
      final status = statuses[person.id] ?? AttendanceStatus.neutral;
      sheet.appendRow([
        TextCellValue(row.toString()),
        TextCellValue(person.firstName),
        TextCellValue(person.lastName),
        TextCellValue(person.groupName ?? ''),
        TextCellValue(status.label),
      ]);
      row++;
    }

    // Summary section
    sheet.appendRow([]); // Empty row
    final present = statuses.values.where((s) =>
        s == AttendanceStatus.present ||
        s == AttendanceStatus.late ||
        s == AttendanceStatus.lateExcused).length;
    final excused = statuses.values.where((s) => s == AttendanceStatus.excused).length;
    final absent = statuses.values.where((s) => s == AttendanceStatus.absent).length;
    final neutral = statuses.values.where((s) => s == AttendanceStatus.neutral).length;
    final total = persons.length;
    final percentage = total > 0 ? (present / total * 100).round() : 0;

    sheet.appendRow([TextCellValue('Zusammenfassung')]);
    sheet.appendRow([TextCellValue('Gesamt'), TextCellValue(total.toString())]);
    sheet.appendRow([TextCellValue('Anwesend'), TextCellValue(present.toString())]);
    sheet.appendRow([TextCellValue('Entschuldigt'), TextCellValue(excused.toString())]);
    sheet.appendRow([TextCellValue('Abwesend'), TextCellValue(absent.toString())]);
    sheet.appendRow([TextCellValue('Offen'), TextCellValue(neutral.toString())]);
    sheet.appendRow([TextCellValue('Quote'), TextCellValue('$percentage%')]);

    // Save and share
    final bytes = Uint8List.fromList(excel.encode()!);
    final fileName = '${tenantName}_Anwesenheit_$dateStr.xlsx';

    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }

  /// Generate plan/program PDF in 2xA5 format (two identical plans side-by-side on A4 landscape)
  /// Useful for cutting in half to have two copies
  Future<void> exportPlanPdf2xA5({
    required BuildContext context,
    required String tenantName,
    required String date,
    required String startTime,
    required String? endTime,
    required List<Map<String, dynamic>> fields,
  }) async {
    final pdf = pw.Document();

    // Calculate times for each field
    final data = <List<String>>[];
    var currentMinutes = _parseTime(startTime);

    for (final field in fields) {
      final name = field['name'] as String? ?? '';
      final conductor = field['conductor'] as String? ?? '';
      final duration = int.tryParse(field['time']?.toString() ?? '0') ?? 0;

      final formattedTime = _formatMinutes(currentMinutes);
      data.add([formattedTime, name, conductor, '$duration\'']);

      currentMinutes += duration;
    }

    // Add end time row
    if (endTime != null) {
      data.add([endTime, 'Ende', '', '']);
    } else {
      data.add([_formatMinutes(currentMinutes), 'Ende', '', '']);
    }

    // Build single plan widget
    pw.Widget buildPlanContent() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Text(
            tenantName,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Probenprogramm $date',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          // Table with smaller font
          pw.TableHelper.fromTextArray(
            headers: ['Zeit', 'Programm', 'Dirigent', ''],
            data: data,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF005238),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.all(4),
            columnWidths: {
              0: const pw.FixedColumnWidth(35),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FixedColumnWidth(25),
            },
          ),
        ],
      );
    }

    // A4 landscape page with two identical A5 halves
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(15),
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left half (A5)
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 10),
                child: buildPlanContent(),
              ),
            ),
            // Vertical divider line (for cutting)
            pw.Container(
              width: 0.5,
              color: PdfColors.grey400,
            ),
            // Right half (A5) - identical content
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10),
                child: buildPlanContent(),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${tenantName}_Probenprogramm_2xA5_$date.pdf',
    );
  }
}
