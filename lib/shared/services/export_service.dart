import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' as html;

import 'export/grade_calculator.dart';
import 'export/excel_style_constants.dart';
import 'export/excel_column_layout.dart';
import 'export/excel_header_builder.dart';
import 'export/excel_max_points_row_builder.dart';
import 'export/excel_student_data_writer.dart';

class ExportService {
  final GradeCalculator _gradeCalc = const GradeCalculator();

  void _log(Object? message) {
    if (kDebugMode) {
      debugPrint('$message');
    }
  }

  // _formatStudentName → _gradeCalc.formatStudentName
  // _truncateHeaderText → _gradeCalc.truncateHeaderText

  /// Generate preview data that matches the actual Excel structure
  /// Returns both preview data and column headers matching Excel output
  Map<String, dynamic> generateExcelPreviewData({
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> classStandingItems,
    required List<Map<String, dynamic>> quizPrelimItems,
    required List<Map<String, dynamic>> midtermExamItems,
    required List<Map<String, dynamic>> pitItems,
    required List<Map<String, dynamic>> finalClassStandingItems,
    required List<Map<String, dynamic>> finalQuizItems,
    required List<Map<String, dynamic>> finalExamItems,
    required List<Map<String, dynamic>> finalPitItems,
    int previewRowCount = 10,
  }) {
    // Take first N students for preview
    final previewStudents = students.take(previewRowCount).toList();

    // Build column headers matching Excel structure
    final columnHeaders = <String>['No.', 'ID Number', 'Name'];

    // Class Standing items
    for (var item in classStandingItems) {
      columnHeaders.add(_gradeCalc.truncateHeaderText(item['title']?.toString() ?? ''));
    }
    columnHeaders.add('Total Score (SRC)');
    columnHeaders.add('CPA');

    // Quiz/Prelim items
    for (var item in quizPrelimItems) {
      columnHeaders.add(_gradeCalc.truncateHeaderText(item['title']?.toString() ?? ''));
    }
    columnHeaders.add('Total Score (SRQ)');
    columnHeaders.add('QA');

    // Midterm Exam items
    for (var item in midtermExamItems) {
      columnHeaders.add(_gradeCalc.truncateHeaderText(item['title']?.toString() ?? ''));
    }
    columnHeaders.add('M');

    // PIT items
    for (var item in pitItems) {
      columnHeaders.add(_gradeCalc.truncateHeaderText(item['title']?.toString() ?? ''));
    }
    columnHeaders.add('Total Score (PIT)');
    columnHeaders.add('PIT%');

    // Midterm Lecture
    columnHeaders.add('MGA');
    columnHeaders.add('Mid Lec Grade Point');
    columnHeaders.add('Mid Grade Point');
    columnHeaders.add('Midterm Grade');

    // Final Class Standing items
    for (var item in finalClassStandingItems) {
      columnHeaders.add(_gradeCalc.truncateHeaderText(item['title']?.toString() ?? ''));
    }
    columnHeaders.add('Total Score (SRC)');
    columnHeaders.add('CPA');

    // Final Quiz items
    for (var item in finalQuizItems) {
      columnHeaders.add(_gradeCalc.truncateHeaderText(item['title']?.toString() ?? ''));
    }
    columnHeaders.add('Total Score (SRQ)');
    columnHeaders.add('QA');

    // Final Exam items
    for (var item in finalExamItems) {
      columnHeaders.add(_gradeCalc.truncateHeaderText(item['title']?.toString() ?? ''));
    }
    columnHeaders.add('F');

    // Final PIT items
    for (var item in finalPitItems) {
      columnHeaders.add(_gradeCalc.truncateHeaderText(item['title']?.toString() ?? ''));
    }
    columnHeaders.add('Total Score (PIT)');
    columnHeaders.add('PIT%');

    // Final Lecture
    columnHeaders.add('FGA');
    columnHeaders.add('Fin Lec Grade Point');
    columnHeaders.add('Fin Grade Point');
    columnHeaders.add('Final Period Grade');

    // Computed Final Grade
    columnHeaders.add('1/2 MTG + 1/2 FTG');
    columnHeaders.add('1/2 MTG + 1/2 FTG (For Removal)');
    columnHeaders.add('1/2 MTG + 1/2 FTG (After Removal)');
    columnHeaders.add('Description');
    columnHeaders.add('1/3 MTG + 2/3 FTG');
    columnHeaders.add('1/3 MTG + 2/3 FTG (For Removal)');
    columnHeaders.add('1/3 MTG + 2/3 FTG (After Removal)');
    columnHeaders.add('Description');

    // Build preview data matching Excel structure
    final previewData =
        previewStudents.asMap().entries.map((entry) {
          final index = entry.key;
          final student = entry.value;
          final previewRow = <String, dynamic>{
            'No.': index + 1,
            'ID Number': student['idNumber'] ?? '',
            'Name': _gradeCalc.formatStudentName(student['name'] ?? ''),
          };

          int colIndex = 3; // Start after No., ID Number, Name

          // Class Standing items
          for (var item in classStandingItems) {
            final key = _gradeCalc.makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _gradeCalc.readScore(student, key);
            colIndex++;
          }
          final csTotal = _gradeCalc.calculateGroupTotal(student, classStandingItems);
          final csPct = _gradeCalc.calculateGroupPercent(student, classStandingItems);
          previewRow[columnHeaders[colIndex++]] = csTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${csPct.round()}%';

          // Quiz/Prelim items
          for (var item in quizPrelimItems) {
            final key = _gradeCalc.makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _gradeCalc.readScore(student, key);
            colIndex++;
          }
          final qpTotal = _gradeCalc.calculateGroupTotal(student, quizPrelimItems);
          final qpPct = _gradeCalc.calculateGroupPercent(student, quizPrelimItems);
          previewRow[columnHeaders[colIndex++]] = qpTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${qpPct.round()}%';

          // Midterm Exam items
          for (var item in midtermExamItems) {
            final key = _gradeCalc.makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _gradeCalc.readScore(student, key);
            colIndex++;
          }
          final mPct = _gradeCalc.calculateGroupPercent(student, midtermExamItems);
          previewRow[columnHeaders[colIndex++]] = '${mPct.round()}%';

          // PIT items
          for (var item in pitItems) {
            final key = _gradeCalc.makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _gradeCalc.readScore(student, key);
            colIndex++;
          }
          final pitTotal = _gradeCalc.calculateGroupTotal(student, pitItems);
          final pitPct = _gradeCalc.calculateGroupPercent(student, pitItems);
          previewRow[columnHeaders[colIndex++]] = pitTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${pitPct.round()}%';

          // Midterm Lecture
          final mga = _gradeCalc.calculateRawMGA(
            student,
            classStandingItems,
            quizPrelimItems,
            midtermExamItems,
            pitItems,
          );
          previewRow[columnHeaders[colIndex++]] = '${(mga * 100).round()}%';
          final midLec = _gradeCalc.gradePointFromRatio(mga);
          previewRow[columnHeaders[colIndex++]] = midLec.toStringAsFixed(3);
          previewRow[columnHeaders[colIndex++]] = midLec.toStringAsFixed(3);
          previewRow[columnHeaders[colIndex++]] = _gradeCalc.mapGradePointToEquivalent(
            midLec,
          );

          // Final Class Standing items
          for (var item in finalClassStandingItems) {
            final key = _gradeCalc.makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _gradeCalc.readScore(student, key);
            colIndex++;
          }
          final fcsTotal = _gradeCalc.calculateGroupTotal(
            student,
            finalClassStandingItems,
          );
          final fcsPct = _gradeCalc.calculateGroupPercent(
            student,
            finalClassStandingItems,
          );
          previewRow[columnHeaders[colIndex++]] = fcsTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${fcsPct.round()}%';

          // Final Quiz items
          for (var item in finalQuizItems) {
            final key = _gradeCalc.makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _gradeCalc.readScore(student, key);
            colIndex++;
          }
          final fqTotal = _gradeCalc.calculateGroupTotal(student, finalQuizItems);
          final fqPct = _gradeCalc.calculateGroupPercent(student, finalQuizItems);
          previewRow[columnHeaders[colIndex++]] = fqTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${fqPct.round()}%';

          // Final Exam items
          for (var item in finalExamItems) {
            final key = _gradeCalc.makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _gradeCalc.readScore(student, key);
            colIndex++;
          }
          final fPct = _gradeCalc.calculateGroupPercent(student, finalExamItems);
          previewRow[columnHeaders[colIndex++]] = '${fPct.round()}%';

          // Final PIT items
          for (var item in finalPitItems) {
            final key = _gradeCalc.makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _gradeCalc.readScore(student, key);
            colIndex++;
          }
          final fpitTotal = _gradeCalc.calculateGroupTotal(student, finalPitItems);
          final fpitPct = _gradeCalc.calculateGroupPercent(student, finalPitItems);
          previewRow[columnHeaders[colIndex++]] = fpitTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${fpitPct.round()}%';

          // Final Lecture
          final fga = _gradeCalc.calculateRawMGA(
            student,
            finalClassStandingItems,
            finalQuizItems,
            finalExamItems,
            finalPitItems,
          );
          previewRow[columnHeaders[colIndex++]] = '${(fga * 100).round()}%';
          final finLec = _gradeCalc.gradePointFromRatio(fga);
          previewRow[columnHeaders[colIndex++]] = finLec.toStringAsFixed(3);
          previewRow[columnHeaders[colIndex++]] = finLec.toStringAsFixed(3);
          previewRow[columnHeaders[colIndex++]] = _gradeCalc.mapGradePointToEquivalent(
            finLec,
          );

          // Computed Final Grade
          final mtg = _gradeCalc.mapGradePointToEquivalentAsNumber(midLec);
          final ftgNum = _gradeCalc.mapGradePointToEquivalentAsNumber(finLec);
          double comp12 = 0.5 * mtg + 0.5 * ftgNum;
          double comp13 = (1.0 / 3.0) * mtg + (2.0 / 3.0) * ftgNum;
          final comp12Mapped = _gradeCalc.gradeLadder(comp12);
          final comp13Mapped = _gradeCalc.gradeLadder(comp13);

          previewRow[columnHeaders[colIndex++]] = comp12.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] =
              comp12Mapped > 3.50 ? '5.00' : comp12Mapped.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] =
              comp12Mapped > 3.50 ? '5.00' : comp12Mapped.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] = _gradeCalc.descFromNumeric(comp12);

          previewRow[columnHeaders[colIndex++]] = comp13.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] =
              comp13Mapped > 3.50 ? '5.00' : comp13Mapped.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] =
              comp13Mapped > 3.50 ? '5.00' : comp13Mapped.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] = _gradeCalc.descFromNumeric(comp13);

          return previewRow;
        }).toList();

    return {'previewData': previewData, 'columnHeaders': columnHeaders};
  }

  /// Get export summary information
  Map<String, dynamic> getExportSummary({
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> classStandingItems,
    required List<Map<String, dynamic>> quizPrelimItems,
    required List<Map<String, dynamic>> midtermExamItems,
    required List<Map<String, dynamic>> pitItems,
    required List<Map<String, dynamic>> finalClassStandingItems,
    required List<Map<String, dynamic>> finalQuizItems,
    required List<Map<String, dynamic>> finalExamItems,
    required List<Map<String, dynamic>> finalPitItems,
    required String sectionName,
    required String courseName,
  }) {
    final totalColumns = ExcelColumnLayout.totalColumnCount(
      csCount: classStandingItems.length,
      qpCount: quizPrelimItems.length,
      meCount: midtermExamItems.length,
      pitCount: pitItems.length,
      fcsCount: finalClassStandingItems.length,
      fqCount: finalQuizItems.length,
      feCount: finalExamItems.length,
      fpitCount: finalPitItems.length,
    );

    return {
      'studentCount': students.length,
      'totalColumns': totalColumns,
      'sectionName': sectionName,
      'courseName': courseName,
      'classStandingItems': classStandingItems.length,
      'quizPrelimItems': quizPrelimItems.length,
      'midtermExamItems': midtermExamItems.length,
      'pitItems': pitItems.length,
      'finalClassStandingItems': finalClassStandingItems.length,
      'finalQuizItems': finalQuizItems.length,
      'finalExamItems': finalExamItems.length,
      'finalPitItems': finalPitItems.length,
    };
  }

  /// Export the complete Class Record (Midterm, Final, Computed) for testing
  Future<void> exportCompleteClassRecord({
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> classStandingItems,
    required List<Map<String, dynamic>> quizPrelimItems,
    required List<Map<String, dynamic>> midtermExamItems,
    required List<Map<String, dynamic>> pitItems,
    required List<Map<String, dynamic>> finalClassStandingItems,
    required List<Map<String, dynamic>> finalQuizItems,
    required List<Map<String, dynamic>> finalExamItems,
    required List<Map<String, dynamic>> finalPitItems,
    required String sectionName,
    required String courseName,
    required String instructorName,
    required String departmentName,
  }) async {
    try {
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Class Record';

      // Note: Auto-filter (sorting arrows) should not be enabled
      // This prevents Excel from auto-sizing row heights for filter dropdowns

      // Build headers similar to the grid layout
      ExcelHeaderBuilder.setupCompleteHeaders(
        sheet,
        _gradeCalc,
        classStandingItems,
        quizPrelimItems,
        midtermExamItems,
        pitItems,
        finalClassStandingItems,
        finalQuizItems,
        finalExamItems,
        finalPitItems,
        sectionName,
        courseName,
        instructorName,
        departmentName,
      );

      // Write Max Points row (aligned below detailed column headers)
      int startRow = 8; // headers at row 7, max points at 8
      ExcelMaxPointsRowBuilder.writeMaxPointsRow(
        sheet,
        startRow,
        _gradeCalc,
        classStandingItems,
        quizPrelimItems,
        midtermExamItems,
        pitItems,
        finalClassStandingItems,
        finalQuizItems,
        finalExamItems,
        finalPitItems,
      );

      ExcelStudentDataWriter.writeCompleteClassRecordData(
        sheet,
        startRow,
        students,
        classStandingItems,
        quizPrelimItems,
        midtermExamItems,
        pitItems,
        finalClassStandingItems,
        finalQuizItems,
        finalExamItems,
        finalPitItems,
        _gradeCalc,
      );
      await _saveAndOpenFile(workbook, '${sectionName}_ClassRecord');
    } catch (e) {
      throw Exception('Failed to export complete class record: $e');
    }
  }


  // Grade calculation helpers now delegated to _gradeCalc (GradeCalculator)


  // ExcelColumnLayout.totalColumnCount() -> delegated to ExcelColumnLayout.totalColumnCount()

  /// Export student list to Excel
  Future<void> exportStudentList({
    required List<Map<String, dynamic>> students,
    required String sectionName,
    required String courseName,
    required String instructorName,
  }) async {
    try {
      // Create a new Excel workbook
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Student List';

      // Set up headers
      ExcelHeaderBuilder.setupStudentListHeaders(sheet, sectionName, courseName, instructorName);

      // Add student data
      ExcelStudentDataWriter.writeStudentListData(sheet, students, _gradeCalc);

      // Auto-fit columns
      _autoFitColumns(sheet);

      // Save and open file
      await _saveAndOpenFile(workbook, '${sectionName}_StudentList');
    } catch (e) {
      throw Exception('Failed to export student list: $e');
    }
  }

  /// Export complete grade sheet to Excel
  Future<void> exportGradeSheet({
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> classStandingItems,
    required List<Map<String, dynamic>> quizPrelimItems,
    required String sectionName,
    required String courseName,
    required String instructorName,
    required String departmentName,
  }) async {
    try {
      _log('🔍 Starting grade sheet export...');
      _log('📊 Students: ${students.length}');
      _log('📋 Class Standing Items: ${classStandingItems.length}');
      _log('📋 Quiz/Prelim Items: ${quizPrelimItems.length}');

      // Create a new Excel workbook
      _log('📝 Creating Excel workbook...');
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Grade Sheet';

      // Set up complete headers
      _log('📋 Setting up headers...');
      ExcelHeaderBuilder.setupGradeSheetHeaders(
        sheet,
        classStandingItems,
        quizPrelimItems,
        sectionName,
        courseName,
        instructorName,
        departmentName,
      );

      // Add student data with scores
      _log('👥 Adding student data...');
      ExcelStudentDataWriter.writeGradeSheetData(
        sheet,
        students,
        classStandingItems,
        quizPrelimItems,
        _gradeCalc,
      );

      // Auto-fit columns
      _log('📏 Auto-fitting columns...');
      _autoFitColumns(sheet);

      // Save and open file
      _log('💾 Saving file...');
      await _saveAndOpenFile(workbook, '${sectionName}_GradeSheet');
      _log('✅ Grade sheet export completed!');
    } catch (e) {
      _log('❌ Grade sheet export error: $e');
      throw Exception('Failed to export grade sheet: $e');
    }
  }

  /// Set up headers for student list export

  /// Set up complete headers for grade sheet export
  void _autoFitColumns(Worksheet sheet) {
    for (int i = 1; i <= sheet.getLastColumn(); i++) {
      sheet.autoFitColumn(i);
    }
  }

  /// Get column letter from number (1 = A, 2 = B, etc.)
  // ExcelColumnLayout.getColumnLetter() -> delegated to ExcelColumnLayout.getColumnLetter()

  /// Save workbook and download file (Web-compatible)
  Future<void> _saveAndOpenFile(Workbook workbook, String fileName) async {
    try {
      _log('🔍 Starting web file download...');

      // Create filename with timestamp
      final now = DateTime.now();
      final timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final fullFileName = '${fileName}_$timestamp.xlsx';

      _log('📄 Filename: $fullFileName');

      // Generate Excel bytes
      _log('💾 Generating Excel bytes...');
      final List<int> bytes = workbook.saveAsStream();
      _log('💾 Excel bytes generated: ${bytes.length} bytes');

      // Convert to Uint8List for web download
      final Uint8List uint8List = Uint8List.fromList(bytes);

      // Create blob and download
      _log('🌐 Creating blob and triggering download...');
      final blob = html.Blob([
        uint8List,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create download link and trigger download
      html.AnchorElement(href: url)
        ..setAttribute('download', fullFileName)
        ..click();

      // Clean up
      html.Url.revokeObjectUrl(url);
      workbook.dispose();
      _log('🗑️ Workbook disposed');

      _log('✅ Web download completed!');
    } catch (e) {
      _log('❌ Web export error: $e');
      throw Exception('Failed to download file: $e');
    }
  }
}
