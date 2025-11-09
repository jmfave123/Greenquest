import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_html/html.dart' as html;

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Helper function to format student name from "Jv P. Tenefrancia" to "TENEFRANCIA, JV P."
  String _formatStudentName(String name) {
    if (name.isEmpty) return '';

    // Split the name into parts
    final parts = name.trim().split(' ');

    if (parts.length < 2) {
      return name.toUpperCase(); // If only one word, return as uppercase
    }

    // Last part is the last name, everything else is first/middle name
    final lastName = parts.last;
    final firstMiddleName = parts.sublist(0, parts.length - 1).join(' ');

    return '${lastName.toUpperCase()}, ${firstMiddleName.toUpperCase()}';
  }

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
      columnHeaders.add(item['title']?.toString() ?? '');
    }
    columnHeaders.add('Total Score (SRC)');
    columnHeaders.add('CPA');

    // Quiz/Prelim items
    for (var item in quizPrelimItems) {
      columnHeaders.add(item['title']?.toString() ?? '');
    }
    columnHeaders.add('Total Score (SRQ)');
    columnHeaders.add('QA');

    // Midterm Exam items
    for (var item in midtermExamItems) {
      columnHeaders.add(item['title']?.toString() ?? '');
    }
    columnHeaders.add('M');

    // PIT items
    for (var item in pitItems) {
      columnHeaders.add(item['title']?.toString() ?? '');
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
      columnHeaders.add(item['title']?.toString() ?? '');
    }
    columnHeaders.add('Total Score (SRC)');
    columnHeaders.add('CPA');

    // Final Quiz items
    for (var item in finalQuizItems) {
      columnHeaders.add(item['title']?.toString() ?? '');
    }
    columnHeaders.add('Total Score (SRQ)');
    columnHeaders.add('QA');

    // Final Exam items
    for (var item in finalExamItems) {
      columnHeaders.add(item['title']?.toString() ?? '');
    }
    columnHeaders.add('F');

    // Final PIT items
    for (var item in finalPitItems) {
      columnHeaders.add(item['title']?.toString() ?? '');
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
            'Name': _formatStudentName(student['name'] ?? ''),
          };

          int colIndex = 3; // Start after No., ID Number, Name

          // Class Standing items
          for (var item in classStandingItems) {
            final key = _makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _readScore(student, key);
            colIndex++;
          }
          final csTotal = _calculateGroupTotal(student, classStandingItems);
          final csPct = _calculateGroupPercent(student, classStandingItems);
          previewRow[columnHeaders[colIndex++]] = csTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${csPct.round()}%';

          // Quiz/Prelim items
          for (var item in quizPrelimItems) {
            final key = _makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _readScore(student, key);
            colIndex++;
          }
          final qpTotal = _calculateGroupTotal(student, quizPrelimItems);
          final qpPct = _calculateGroupPercent(student, quizPrelimItems);
          previewRow[columnHeaders[colIndex++]] = qpTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${qpPct.round()}%';

          // Midterm Exam items
          for (var item in midtermExamItems) {
            final key = _makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _readScore(student, key);
            colIndex++;
          }
          final mPct = _calculateGroupPercent(student, midtermExamItems);
          previewRow[columnHeaders[colIndex++]] = '${mPct.round()}%';

          // PIT items
          for (var item in pitItems) {
            final key = _makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _readScore(student, key);
            colIndex++;
          }
          final pitTotal = _calculateGroupTotal(student, pitItems);
          final pitPct = _calculateGroupPercent(student, pitItems);
          previewRow[columnHeaders[colIndex++]] = pitTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${pitPct.round()}%';

          // Midterm Lecture
          final mga = _calculateRawMGAFromGroups(
            student,
            classStandingItems,
            quizPrelimItems,
            midtermExamItems,
            pitItems,
          );
          previewRow[columnHeaders[colIndex++]] = '${(mga * 100).round()}%';
          final midLec = _gradePointFromRatio(mga);
          previewRow[columnHeaders[colIndex++]] = midLec.toStringAsFixed(3);
          previewRow[columnHeaders[colIndex++]] = midLec.toStringAsFixed(3);
          previewRow[columnHeaders[colIndex++]] = _mapGradePointToEquivalent(
            midLec,
          );

          // Final Class Standing items
          for (var item in finalClassStandingItems) {
            final key = _makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _readScore(student, key);
            colIndex++;
          }
          final fcsTotal = _calculateGroupTotal(
            student,
            finalClassStandingItems,
          );
          final fcsPct = _calculateGroupPercent(
            student,
            finalClassStandingItems,
          );
          previewRow[columnHeaders[colIndex++]] = fcsTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${fcsPct.round()}%';

          // Final Quiz items
          for (var item in finalQuizItems) {
            final key = _makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _readScore(student, key);
            colIndex++;
          }
          final fqTotal = _calculateGroupTotal(student, finalQuizItems);
          final fqPct = _calculateGroupPercent(student, finalQuizItems);
          previewRow[columnHeaders[colIndex++]] = fqTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${fqPct.round()}%';

          // Final Exam items
          for (var item in finalExamItems) {
            final key = _makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _readScore(student, key);
            colIndex++;
          }
          final fPct = _calculateGroupPercent(student, finalExamItems);
          previewRow[columnHeaders[colIndex++]] = '${fPct.round()}%';

          // Final PIT items
          for (var item in finalPitItems) {
            final key = _makeItemKey(item);
            previewRow[columnHeaders[colIndex]] = _readScore(student, key);
            colIndex++;
          }
          final fpitTotal = _calculateGroupTotal(student, finalPitItems);
          final fpitPct = _calculateGroupPercent(student, finalPitItems);
          previewRow[columnHeaders[colIndex++]] = fpitTotal.toString();
          previewRow[columnHeaders[colIndex++]] = '${fpitPct.round()}%';

          // Final Lecture
          final fga = _calculateRawMGAFromGroups(
            student,
            finalClassStandingItems,
            finalQuizItems,
            finalExamItems,
            finalPitItems,
          );
          previewRow[columnHeaders[colIndex++]] = '${(fga * 100).round()}%';
          final finLec = _gradePointFromRatio(fga);
          previewRow[columnHeaders[colIndex++]] = finLec.toStringAsFixed(3);
          previewRow[columnHeaders[colIndex++]] = finLec.toStringAsFixed(3);
          previewRow[columnHeaders[colIndex++]] = _mapGradePointToEquivalent(
            finLec,
          );

          // Computed Final Grade
          final mtg = _mapGradePointToEquivalentAsNumber(midLec);
          final ftgNum = _mapGradePointToEquivalentAsNumber(finLec);
          double comp12 = 0.5 * mtg + 0.5 * ftgNum;
          double comp13 = (1.0 / 3.0) * mtg + (2.0 / 3.0) * ftgNum;
          final comp12Mapped = _gradeLadder(comp12);
          final comp13Mapped = _gradeLadder(comp13);

          previewRow[columnHeaders[colIndex++]] = comp12.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] =
              comp12Mapped > 3.50 ? '5.00' : comp12Mapped.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] =
              comp12Mapped > 3.50 ? '5.00' : comp12Mapped.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] = _descFromNumeric(comp12);

          previewRow[columnHeaders[colIndex++]] = comp13.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] =
              comp13Mapped > 3.50 ? '5.00' : comp13Mapped.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] =
              comp13Mapped > 3.50 ? '5.00' : comp13Mapped.toStringAsFixed(2);
          previewRow[columnHeaders[colIndex++]] = _descFromNumeric(comp13);

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
    final totalColumns = _totalColumnCount(
      classStandingItems,
      quizPrelimItems,
      midtermExamItems,
      pitItems,
      finalClassStandingItems,
      finalQuizItems,
      finalExamItems,
      finalPitItems,
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
      _setupCompleteHeaders(
        sheet,
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
      _writeMaxPointsRow(
        sheet,
        startRow,
        classStandingItems,
        quizPrelimItems,
        midtermExamItems,
        pitItems,
        finalClassStandingItems,
        finalQuizItems,
        finalExamItems,
        finalPitItems,
      );

      // Write students
      for (int i = 0; i < students.length; i++) {
        final student = students[i];
        final row = startRow + 1 + i;
        int col = 1;

        // No, ID, Names
        sheet.getRangeByName('${_getColumnLetter(col++)}$row').setNumber(i + 1);
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(student['idNumber'] ?? '');
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(_formatStudentName(student['name'] ?? ''));

        // Class Standing items
        int csItemsStartCol = col;
        for (var item in classStandingItems) {
          final key = _makeItemKey(item);
          sheet
              .getRangeByName('${_getColumnLetter(col++)}$row')
              .setText(_readScore(student, key));
        }
        int csItemsEndCol = col;
        // Total (SRC) and CPA
        final csTotal = _calculateGroupTotal(student, classStandingItems);
        final csPct = _calculateGroupPercent(student, classStandingItems);
        int srcMidCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(csTotal.toString());
        int cpaMidCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${csPct.round()}%');

        // Quiz/Prelim items
        int qpItemsStartCol = col;
        for (var item in quizPrelimItems) {
          final key = _makeItemKey(item);
          sheet
              .getRangeByName('${_getColumnLetter(col++)}$row')
              .setText(_readScore(student, key));
        }
        int qpItemsEndCol = col;
        final qpTotal = _calculateGroupTotal(student, quizPrelimItems);
        final qpPct = _calculateGroupPercent(student, quizPrelimItems);
        int srqMidCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(qpTotal.toString());
        int qaMidCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${qpPct.round()}%');

        // Midterm Exam items
        int meItemsStartCol = col;
        for (var item in midtermExamItems) {
          final key = _makeItemKey(item);
          sheet
              .getRangeByName('${_getColumnLetter(col++)}$row')
              .setText(_readScore(student, key));
        }
        int meItemsEndCol = col;
        final mPct = _calculateGroupPercent(student, midtermExamItems);
        int mCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${mPct.round()}%');

        // PIT items
        int pitItemsStartCol = col;
        for (var item in pitItems) {
          final key = _makeItemKey(item);
          sheet
              .getRangeByName('${_getColumnLetter(col++)}$row')
              .setText(_readScore(student, key));
        }
        int pitItemsEndCol = col;
        final pitTotal = _calculateGroupTotal(student, pitItems);
        final pitPct = _calculateGroupPercent(student, pitItems);
        int pitTotalMidCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(pitTotal.toString());
        int pitPercentMidCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${pitPct.round()}%');

        // Lecture (Midterm)
        final mga = _calculateRawMGAFromGroups(
          student,
          classStandingItems,
          quizPrelimItems,
          midtermExamItems,
          pitItems,
        );
        int mgaCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${(mga * 100).round()}%');
        final midLec = _gradePointFromRatio(mga);
        int midLecGradePointCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(midLec.toStringAsFixed(3));
        int midGradePointCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(midLec.toStringAsFixed(3));
        int midtermGradeDataCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(_mapGradePointToEquivalent(midLec));

        // Final Class Standing items
        int fcsItemsStartCol = col;
        for (var item in finalClassStandingItems) {
          final key = _makeItemKey(item);
          sheet
              .getRangeByName('${_getColumnLetter(col++)}$row')
              .setText(_readScore(student, key));
        }
        int fcsItemsEndCol = col;
        final fcsTotal = _calculateGroupTotal(student, finalClassStandingItems);
        final fcsPct = _calculateGroupPercent(student, finalClassStandingItems);
        int srcFinalCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(fcsTotal.toString());
        int cpaFinalCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${fcsPct.round()}%');

        // Final Quiz items
        int fqItemsStartCol = col;
        for (var item in finalQuizItems) {
          final key = _makeItemKey(item);
          sheet
              .getRangeByName('${_getColumnLetter(col++)}$row')
              .setText(_readScore(student, key));
        }
        int fqItemsEndCol = col;
        final fqTotal = _calculateGroupTotal(student, finalQuizItems);
        final fqPct = _calculateGroupPercent(student, finalQuizItems);
        int srqFinalCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(fqTotal.toString());
        int qaFinalCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${fqPct.round()}%');

        // Final Exam items
        int feItemsStartCol = col;
        for (var item in finalExamItems) {
          final key = _makeItemKey(item);
          sheet
              .getRangeByName('${_getColumnLetter(col++)}$row')
              .setText(_readScore(student, key));
        }
        int feItemsEndCol = col;
        final fPct = _calculateGroupPercent(student, finalExamItems);
        int fCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${fPct.round()}%');

        // Final PIT items
        int fpitItemsStartCol = col;
        for (var item in finalPitItems) {
          final key = _makeItemKey(item);
          sheet
              .getRangeByName('${_getColumnLetter(col++)}$row')
              .setText(_readScore(student, key));
        }
        int fpitItemsEndCol = col;
        final fpitTotal = _calculateGroupTotal(student, finalPitItems);
        final fpitPct = _calculateGroupPercent(student, finalPitItems);
        int pitTotalFinalCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(fpitTotal.toString());
        int pitPercentFinalCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${fpitPct.round()}%');

        // Final Lecture
        final fga = _calculateRawMGAFromGroups(
          student,
          finalClassStandingItems,
          finalQuizItems,
          finalExamItems,
          finalPitItems,
        );
        int fgaCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText('${(fga * 100).round()}%');
        final finLec = _gradePointFromRatio(fga);
        int finLecGradePointCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(finLec.toStringAsFixed(3));
        int finGradePointCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(finLec.toStringAsFixed(3));
        final ftg = _mapGradePointToEquivalent(finLec);
        int finalPeriodGradeDataCol = col;
        sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText(ftg);

        // Computed Final Grade section
        final mtg = _mapGradePointToEquivalentAsNumber(midLec);
        final ftgNum = _mapGradePointToEquivalentAsNumber(finLec);

        double comp12 = 0.5 * mtg + 0.5 * ftgNum;
        double comp13 = (1.0 / 3.0) * mtg + (2.0 / 3.0) * ftgNum;

        // 1/2 MTG + 1/2 FTG
        int comp12Col = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(comp12.toStringAsFixed(2));
        // For Removal (cap > 3.50 -> 5.00)
        final comp12Mapped = _gradeLadder(comp12);
        int comp12RemovalCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(
              comp12Mapped > 3.50 ? '5.00' : comp12Mapped.toStringAsFixed(2),
            );
        // After Removal (copy For Removal)
        int comp12AfterCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(
              comp12Mapped > 3.50 ? '5.00' : comp12Mapped.toStringAsFixed(2),
            );
        // Description
        int comp12DescCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(_descFromNumeric(comp12));

        // 1/3 MTG + 2/3 FTG
        int comp13Col = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(comp13.toStringAsFixed(2));
        final comp13Mapped = _gradeLadder(comp13);
        int comp13RemovalCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(
              comp13Mapped > 3.50 ? '5.00' : comp13Mapped.toStringAsFixed(2),
            );
        int comp13AfterCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(
              comp13Mapped > 3.50 ? '5.00' : comp13Mapped.toStringAsFixed(2),
            );
        int comp13DescCol = col;
        sheet
            .getRangeByName('${_getColumnLetter(col++)}$row')
            .setText(_descFromNumeric(comp13));

        // Row borders
        final rowRange = sheet.getRangeByName(
          'A$row:${_getColumnLetter(col - 1)}$row',
        );
        rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Apply bold and foreground color #333399 to Total Score, CPA, QA, M, PIT%, MGA (both midterm and final)
        // Midterm columns
        sheet
            .getRangeByName('${_getColumnLetter(srcMidCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(srcMidCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(cpaMidCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(cpaMidCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(srqMidCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(srqMidCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(qaMidCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(qaMidCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet.getRangeByName('${_getColumnLetter(mCol)}$row').cellStyle.bold =
            true;
        sheet
            .getRangeByName('${_getColumnLetter(mCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(pitTotalMidCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(pitTotalMidCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(pitPercentMidCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(pitPercentMidCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet.getRangeByName('${_getColumnLetter(mgaCol)}$row').cellStyle.bold =
            true;
        sheet
            .getRangeByName('${_getColumnLetter(mgaCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        // Final columns
        sheet
            .getRangeByName('${_getColumnLetter(srcFinalCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(srcFinalCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(cpaFinalCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(cpaFinalCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(srqFinalCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(srqFinalCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(qaFinalCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(qaFinalCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet.getRangeByName('${_getColumnLetter(fCol)}$row').cellStyle.bold =
            true;
        sheet
            .getRangeByName('${_getColumnLetter(fCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(pitTotalFinalCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(pitTotalFinalCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet
            .getRangeByName('${_getColumnLetter(pitPercentFinalCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(pitPercentFinalCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        sheet.getRangeByName('${_getColumnLetter(fgaCol)}$row').cellStyle.bold =
            true;
        sheet
            .getRangeByName('${_getColumnLetter(fgaCol)}$row')
            .cellStyle
            .fontColor = '#333399';

        // Apply white background to item columns (assignments, quizzes, etc.)
        if (csItemsEndCol > csItemsStartCol) {
          final csItemsRange = sheet.getRangeByName(
            '${_getColumnLetter(csItemsStartCol)}$row:${_getColumnLetter(csItemsEndCol - 1)}$row',
          );
          csItemsRange.cellStyle.backColor = '#FFFFFF';
        }
        if (qpItemsEndCol > qpItemsStartCol) {
          final qpItemsRange = sheet.getRangeByName(
            '${_getColumnLetter(qpItemsStartCol)}$row:${_getColumnLetter(qpItemsEndCol - 1)}$row',
          );
          qpItemsRange.cellStyle.backColor = '#FFFFFF';
        }
        if (meItemsEndCol > meItemsStartCol) {
          final meItemsRange = sheet.getRangeByName(
            '${_getColumnLetter(meItemsStartCol)}$row:${_getColumnLetter(meItemsEndCol - 1)}$row',
          );
          meItemsRange.cellStyle.backColor = '#FFFFFF';
        }
        if (pitItemsEndCol > pitItemsStartCol) {
          final pitItemsRange = sheet.getRangeByName(
            '${_getColumnLetter(pitItemsStartCol)}$row:${_getColumnLetter(pitItemsEndCol - 1)}$row',
          );
          pitItemsRange.cellStyle.backColor = '#FFFFFF';
        }
        if (fcsItemsEndCol > fcsItemsStartCol) {
          final fcsItemsRange = sheet.getRangeByName(
            '${_getColumnLetter(fcsItemsStartCol)}$row:${_getColumnLetter(fcsItemsEndCol - 1)}$row',
          );
          fcsItemsRange.cellStyle.backColor = '#FFFFFF';
        }
        if (fqItemsEndCol > fqItemsStartCol) {
          final fqItemsRange = sheet.getRangeByName(
            '${_getColumnLetter(fqItemsStartCol)}$row:${_getColumnLetter(fqItemsEndCol - 1)}$row',
          );
          fqItemsRange.cellStyle.backColor = '#FFFFFF';
        }
        if (feItemsEndCol > feItemsStartCol) {
          final feItemsRange = sheet.getRangeByName(
            '${_getColumnLetter(feItemsStartCol)}$row:${_getColumnLetter(feItemsEndCol - 1)}$row',
          );
          feItemsRange.cellStyle.backColor = '#FFFFFF';
        }
        if (fpitItemsEndCol > fpitItemsStartCol) {
          final fpitItemsRange = sheet.getRangeByName(
            '${_getColumnLetter(fpitItemsStartCol)}$row:${_getColumnLetter(fpitItemsEndCol - 1)}$row',
          );
          fpitItemsRange.cellStyle.backColor = '#FFFFFF';
        }

        // Apply #C6E0B4 background to Mid Lec Grade Point and Fin Lec Grade Point columns
        sheet
            .getRangeByName('${_getColumnLetter(midLecGradePointCol)}$row')
            .cellStyle
            .backColor = '#C6E0B4';
        sheet
            .getRangeByName('${_getColumnLetter(finLecGradePointCol)}$row')
            .cellStyle
            .backColor = '#C6E0B4';

        // Apply #FFC000 background to Midterm Grade and Final Period Grade columns
        sheet
            .getRangeByName('${_getColumnLetter(midtermGradeDataCol)}$row')
            .cellStyle
            .backColor = '#FFC000';
        sheet
            .getRangeByName('${_getColumnLetter(finalPeriodGradeDataCol)}$row')
            .cellStyle
            .backColor = '#FFC000';

        // Apply bold and conditional color to Mid Lec Grade Point, Mid Grade Point, Midterm Grade values
        // Green if passing (<= 3.00), Red if failing (> 3.00)
        double midLecValue = double.tryParse(midLec.toStringAsFixed(3)) ?? 5.00;
        String midLecColor = midLecValue <= 3.00 ? '#34A853' : '#E53935';

        sheet
            .getRangeByName('${_getColumnLetter(midLecGradePointCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(midLecGradePointCol)}$row')
            .cellStyle
            .fontColor = midLecColor;

        sheet
            .getRangeByName('${_getColumnLetter(midGradePointCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(midGradePointCol)}$row')
            .cellStyle
            .fontColor = midLecColor;

        double midtermGradeValue =
            double.tryParse(_mapGradePointToEquivalent(midLec)) ?? 5.00;
        String midtermGradeColor =
            midtermGradeValue <= 3.00 ? '#34A853' : '#E53935';

        sheet
            .getRangeByName('${_getColumnLetter(midtermGradeDataCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(midtermGradeDataCol)}$row')
            .cellStyle
            .fontColor = midtermGradeColor;

        // Apply bold and conditional color to Fin Lec Grade Point, Fin Grade Point, Final Period Grade values
        // Green if passing (<= 3.00), Red if failing (> 3.00)
        double finLecValue = double.tryParse(finLec.toStringAsFixed(3)) ?? 5.00;
        String finLecColor = finLecValue <= 3.00 ? '#34A853' : '#E53935';

        sheet
            .getRangeByName('${_getColumnLetter(finLecGradePointCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(finLecGradePointCol)}$row')
            .cellStyle
            .fontColor = finLecColor;

        sheet
            .getRangeByName('${_getColumnLetter(finGradePointCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(finGradePointCol)}$row')
            .cellStyle
            .fontColor = finLecColor;

        double finalGradeValue = double.tryParse(ftg) ?? 5.00;
        String finalGradeColor =
            finalGradeValue <= 3.00 ? '#34A853' : '#E53935';

        sheet
            .getRangeByName('${_getColumnLetter(finalPeriodGradeDataCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(finalPeriodGradeDataCol)}$row')
            .cellStyle
            .fontColor = finalGradeColor;

        // Apply bold and conditional color to all computed final grade values
        // Green if passing (<= 3.00), Red if failing (> 3.00)

        // 1/2 MTG + 1/2 FTG values
        double comp12Value = comp12;
        String comp12Color = comp12Value <= 3.00 ? '#34A853' : '#E53935';
        sheet
            .getRangeByName('${_getColumnLetter(comp12Col)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(comp12Col)}$row')
            .cellStyle
            .fontColor = comp12Color;

        double comp12RemovalValue = comp12Mapped > 3.50 ? 5.00 : comp12Mapped;
        String comp12RemovalColor =
            comp12RemovalValue <= 3.00 ? '#34A853' : '#E53935';
        sheet
            .getRangeByName('${_getColumnLetter(comp12RemovalCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(comp12RemovalCol)}$row')
            .cellStyle
            .fontColor = comp12RemovalColor;

        sheet
            .getRangeByName('${_getColumnLetter(comp12AfterCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(comp12AfterCol)}$row')
            .cellStyle
            .fontColor = comp12RemovalColor;

        // Description for comp12 - color based on text
        String comp12Desc = _descFromNumeric(comp12);
        String comp12DescColor =
            comp12Desc.toLowerCase() == 'failed'
                ? '#E53935'
                : (comp12Desc.toLowerCase() == 'excellent'
                    ? '#34A853'
                    : '#000000');
        sheet
            .getRangeByName('${_getColumnLetter(comp12DescCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(comp12DescCol)}$row')
            .cellStyle
            .fontColor = comp12DescColor;

        // 1/3 MTG + 2/3 FTG values
        double comp13Value = comp13;
        String comp13Color = comp13Value <= 3.00 ? '#34A853' : '#E53935';
        sheet
            .getRangeByName('${_getColumnLetter(comp13Col)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(comp13Col)}$row')
            .cellStyle
            .fontColor = comp13Color;

        double comp13RemovalValue = comp13Mapped > 3.50 ? 5.00 : comp13Mapped;
        String comp13RemovalColor =
            comp13RemovalValue <= 3.00 ? '#34A853' : '#E53935';
        sheet
            .getRangeByName('${_getColumnLetter(comp13RemovalCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(comp13RemovalCol)}$row')
            .cellStyle
            .fontColor = comp13RemovalColor;

        sheet
            .getRangeByName('${_getColumnLetter(comp13AfterCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(comp13AfterCol)}$row')
            .cellStyle
            .fontColor = comp13RemovalColor;

        // Description for comp13 - color based on text
        String comp13Desc = _descFromNumeric(comp13);
        String comp13DescColor =
            comp13Desc.toLowerCase() == 'failed'
                ? '#E53935'
                : (comp13Desc.toLowerCase() == 'excellent'
                    ? '#34A853'
                    : '#000000');
        sheet
            .getRangeByName('${_getColumnLetter(comp13DescCol)}$row')
            .cellStyle
            .bold = true;
        sheet
            .getRangeByName('${_getColumnLetter(comp13DescCol)}$row')
            .cellStyle
            .fontColor = comp13DescColor;

        // Apply white background to all computed final grade columns (8 columns)
        final computedRange = sheet.getRangeByName(
          '${_getColumnLetter(comp12Col)}$row:${_getColumnLetter(comp13DescCol)}$row',
        );
        computedRange.cellStyle.backColor = '#FFFFFF';
      }

      // Center all content in row 9 (first student row)
      if (students.isNotEmpty) {
        final row9 = startRow + 1; // First student row
        final totalCols = _totalColumnCount(
          classStandingItems,
          quizPrelimItems,
          midtermExamItems,
          pitItems,
          finalClassStandingItems,
          finalQuizItems,
          finalExamItems,
          finalPitItems,
        );
        final row9Range = sheet.getRangeByName(
          'A$row9:${_getColumnLetter(totalCols)}$row9',
        );
        row9Range.cellStyle.hAlign = HAlignType.center;
        row9Range.cellStyle.vAlign = VAlignType.center;
      }

      _autoFitColumns(sheet);

      // Force row 7 height again after all operations (Excel may try to recalculate)
      // Row index is 0-based, so row 7 is index 6
      final row7 = sheet.rows[6];
      if (row7 != null) {
        row7.height = 15; // Default row height to match other rows
        // Also try setting it on the row range to ensure it sticks
        final row7Range = sheet.getRangeByName(
          'A7:${_getColumnLetter(_totalColumnCount(classStandingItems, quizPrelimItems, midtermExamItems, pitItems, finalClassStandingItems, finalQuizItems, finalExamItems, finalPitItems))}7',
        );
        // Ensure wrapText is still false
        row7Range.cellStyle.wrapText = false;
      }

      await _saveAndOpenFile(workbook, '${sectionName}_ClassRecord');
    } catch (e) {
      Get.snackbar(
        'Export Error',
        'Failed to export complete class record: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _setupCompleteHeaders(
    Worksheet sheet,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    List<Map<String, dynamic>> midtermExamItems,
    List<Map<String, dynamic>> pitItems,
    List<Map<String, dynamic>> finalClassStandingItems,
    List<Map<String, dynamic>> finalQuizItems,
    List<Map<String, dynamic>> finalExamItems,
    List<Map<String, dynamic>> finalPitItems,
    String sectionName,
    String courseName,
    String instructorName,
    String departmentName,
  ) {
    int row = 1;

    // Calculate group sizes
    final csGroup = classStandingItems.length + 2; // items + SRC + CPA
    final qpGroup = quizPrelimItems.length + 2; // items + SRQ + QA
    final meGroup = midtermExamItems.length + 1; // items + M
    final pitGroup = pitItems.length + 2; // items + total + %
    final midLectureGroup = 4; // MGA + Mid Lec + Mid GP + Midterm Grade
    final midtermGroup =
        csGroup + qpGroup + meGroup + pitGroup + midLectureGroup;

    final fcsGroup = finalClassStandingItems.length + 2;
    final fqGroup = finalQuizItems.length + 2;
    final feGroup = finalExamItems.length + 1;
    final fpitGroup = finalPitItems.length + 2;
    final finalLectureGroup = 4;
    final finalGroup =
        fcsGroup + fqGroup + feGroup + fpitGroup + finalLectureGroup;

    final computedGroup = 8;

    // Row 1: Department (merged across all columns)
    final totalColumns = 3 + midtermGroup + finalGroup + computedGroup;
    sheet.getRangeByName('A1:${_getColumnLetter(totalColumns)}1').merge();
    sheet
        .getRangeByName('A1')
        .setText('Department of NATIONAL SERVICE TRAINING PROGRAM');
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A1').cellStyle.backColor = '#FFFFFF';

    // Row 2: Subject (merged across all columns)
    sheet.getRangeByName('A2:${_getColumnLetter(totalColumns)}2').merge();
    sheet.getRangeByName('A2').setText('Subject: NSTP 101C');
    sheet.getRangeByName('A2').cellStyle.bold = true;
    sheet.getRangeByName('A2').cellStyle.backColor = '#FFFFFF';

    // Row 4: Top stacked headers for sections
    row = 4;
    int col = 1;
    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + 3 - 1)}$row',
        )
        .merge();
    // spacer for student info columns
    sheet.getRangeByName('${_getColumnLetter(col)}$row').setText('');
    col += 3;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + midtermGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Midterm Grade');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#99CCFF';
    col += midtermGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + finalGroup - 1)}$row',
        )
        .merge();
    sheet.getRangeByName('${_getColumnLetter(col)}$row').setText('Final Grade');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#99CCFF';
    col += finalGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + computedGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Computed Final Grade');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#66BB6A';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.fontColor =
        '#FFFFFF';

    // Row 5: Lecture 100% over midterm and final groups
    row = 5;
    col = 4;
    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + midtermGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Lecture 100%');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FFC000';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;

    col += midtermGroup;
    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + finalGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Lecture 100%');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FFC000';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;

    // Computed group spacer
    col += finalGroup;
    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + computedGroup - 1)}$row',
        )
        .merge();

    // Row 6: Category headers for midterm and final groups
    row = 6;
    col = 4; // midterm start
    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + csGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Class Standing Performance Items (10%)');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    col += csGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + qpGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Quiz/Prelim Performance Item (40%)');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    col += qpGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + meGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Midterm Exam (30%)');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    col += meGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + pitGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Per Inno Task (20%)');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    col += pitGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + midLectureGroup - 1)}$row',
        )
        .merge();
    sheet.getRangeByName('${_getColumnLetter(col)}$row').setText('Lecture');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;

    // Final categories
    col = 4 + midtermGroup;
    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + fcsGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Class Standing Performance Items (10%)');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    col += fcsGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + fqGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Quiz/Pre-final\nPerformance Item (40%)');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.wrapText =
        true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    col += fqGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + feGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Final Exam (30%)');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    col += feGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + fpitGroup - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(col)}$row')
        .setText('Per Inno Task (20%)');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;
    col += fpitGroup;

    sheet
        .getRangeByName(
          '${_getColumnLetter(col)}$row:${_getColumnLetter(col + finalLectureGroup - 1)}$row',
        )
        .merge();
    sheet.getRangeByName('${_getColumnLetter(col)}$row').setText('Lecture');
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.backColor =
        '#FCF305';
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.bold = true;
    sheet.getRangeByName('${_getColumnLetter(col)}$row').cellStyle.hAlign =
        HAlignType.center;

    // Row 7: Detailed column headers
    row = 7;
    col = 1;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('');

    // Track column positions for vertical rotation
    int csItemsStartCol = col;
    for (var item in classStandingItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? '');
    }
    int csItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Total Score (SRC)');
    int cpaMidCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('CPA');

    int qpItemsStartCol = col;
    for (var item in quizPrelimItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? '');
    }
    int qpItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Total Score (SRQ)');
    int qaMidCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('QA');

    int meItemsStartCol = col;
    for (var item in midtermExamItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? '');
    }
    int meItemsEndCol = col;
    int mCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('M');

    int pitItemsStartCol = col;
    for (var item in pitItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? '');
    }
    int pitItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Total Score (PIT)');
    int pitPercentMidCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('PIT%');

    int mgaCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('MGA');
    int midLecGradePointCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Mid Lec Grade Point');
    int midGradePointCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Mid Grade Point');
    int midtermGradeCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Midterm Grade');

    int fcsItemsStartCol = col;
    for (var item in finalClassStandingItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? '');
    }
    int fcsItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Total Score (SRC)');
    int cpaFinalCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('CPA');

    int fqItemsStartCol = col;
    for (var item in finalQuizItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? '');
    }
    int fqItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Total Score (SRQ)');
    int qaFinalCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('QA');

    int feItemsStartCol = col;
    for (var item in finalExamItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? '');
    }
    int feItemsEndCol = col;
    int fCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('F');

    int fpitItemsStartCol = col;
    for (var item in finalPitItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? '');
    }
    int fpitItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Total Score (PIT)');
    int pitPercentFinalCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('PIT%');

    int fgaCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('FGA');
    int finLecGradePointCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Fin Lec Grade Point');
    int finGradePointCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Fin Grade Point');
    int finalPeriodGradeCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Final Period Grade');

    int computedStartCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('1/2 MTG + 1/2 FTG');
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('1/2 MTG + 1/2 FTG (For Removal)');
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('1/2 MTG + 1/2 FTG (After Removal)');
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Description');
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('1/3 MTG + 2/3 FTG');
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('1/3 MTG + 2/3 FTG (For Removal)');
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('1/3 MTG + 2/3 FTG (After Removal)');
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Description');

    // Set header styling - all normal first
    final headerRange = sheet.getRangeByName(
      'A$row:${_getColumnLetter(col - 1)}$row',
    );
    headerRange.cellStyle.bold = false; // Set all to normal first
    headerRange.cellStyle.backColor = '#FFFFFF'; // White background
    headerRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

    // Set bold for specific columns: Midterm
    sheet.getRangeByName('${_getColumnLetter(cpaMidCol)}$row').cellStyle.bold =
        true;
    sheet.getRangeByName('${_getColumnLetter(qaMidCol)}$row').cellStyle.bold =
        true;
    sheet.getRangeByName('${_getColumnLetter(mCol)}$row').cellStyle.bold = true;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentMidCol)}$row')
        .cellStyle
        .bold = true;
    sheet.getRangeByName('${_getColumnLetter(mgaCol)}$row').cellStyle.bold =
        true;
    sheet
        .getRangeByName('${_getColumnLetter(midLecGradePointCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${_getColumnLetter(midGradePointCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${_getColumnLetter(midtermGradeCol)}$row')
        .cellStyle
        .bold = true;
    // Apply #FFC000 background to Midterm Grade header
    sheet
        .getRangeByName('${_getColumnLetter(midtermGradeCol)}$row')
        .cellStyle
        .backColor = '#FFC000';

    // Set bold for specific columns: Final
    sheet
        .getRangeByName('${_getColumnLetter(cpaFinalCol)}$row')
        .cellStyle
        .bold = true;
    sheet.getRangeByName('${_getColumnLetter(qaFinalCol)}$row').cellStyle.bold =
        true;
    sheet.getRangeByName('${_getColumnLetter(fCol)}$row').cellStyle.bold = true;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentFinalCol)}$row')
        .cellStyle
        .bold = true;
    sheet.getRangeByName('${_getColumnLetter(fgaCol)}$row').cellStyle.bold =
        true;
    sheet
        .getRangeByName('${_getColumnLetter(finLecGradePointCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${_getColumnLetter(finGradePointCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${_getColumnLetter(finalPeriodGradeCol)}$row')
        .cellStyle
        .bold = true;
    // Apply #FFC000 background to Final Period Grade header
    sheet
        .getRangeByName('${_getColumnLetter(finalPeriodGradeCol)}$row')
        .cellStyle
        .backColor = '#FFC000';

    // Set bold for all computed final grade columns (8 columns)
    for (int i = computedStartCol; i < col; i++) {
      sheet.getRangeByName('${_getColumnLetter(i)}$row').cellStyle.bold = true;
    }

    // Make the first three header cells (No., ID Number, Names) appear white
    // to look like normal cells after removing labels.
    final infoHeaderRange = sheet.getRangeByName('A$row:C$row');
    infoHeaderRange.cellStyle.backColor = '#FFFFFF';

    // Apply vertical text rotation (90 degrees) to item columns and related columns
    // This makes them read from bottom to top, like in the image

    // Midterm item columns
    if (csItemsEndCol > csItemsStartCol) {
      for (int i = csItemsStartCol; i < csItemsEndCol; i++) {
        final cell = sheet.getRangeByName('${_getColumnLetter(i)}$row');
        cell.cellStyle.rotation =
            90; // 90 degrees rotation (vertical, reading bottom to top)
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }
    // CPA, Total Score columns for midterm
    sheet
        .getRangeByName('${_getColumnLetter(cpaMidCol - 1)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(cpaMidCol - 1)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(cpaMidCol - 1)}$row')
        .cellStyle
        .vAlign = VAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(cpaMidCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(cpaMidCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(cpaMidCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    if (qpItemsEndCol > qpItemsStartCol) {
      for (int i = qpItemsStartCol; i < qpItemsEndCol; i++) {
        final cell = sheet.getRangeByName('${_getColumnLetter(i)}$row');
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }
    // QA, Total Score columns for midterm
    sheet
        .getRangeByName('${_getColumnLetter(qaMidCol - 1)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(qaMidCol - 1)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(qaMidCol - 1)}$row')
        .cellStyle
        .vAlign = VAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(qaMidCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet.getRangeByName('${_getColumnLetter(qaMidCol)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet.getRangeByName('${_getColumnLetter(qaMidCol)}$row').cellStyle.vAlign =
        VAlignType.center;

    if (meItemsEndCol > meItemsStartCol) {
      for (int i = meItemsStartCol; i < meItemsEndCol; i++) {
        final cell = sheet.getRangeByName('${_getColumnLetter(i)}$row');
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }
    // M column
    sheet.getRangeByName('${_getColumnLetter(mCol)}$row').cellStyle.rotation =
        90;
    sheet.getRangeByName('${_getColumnLetter(mCol)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet.getRangeByName('${_getColumnLetter(mCol)}$row').cellStyle.vAlign =
        VAlignType.center;

    if (pitItemsEndCol > pitItemsStartCol) {
      for (int i = pitItemsStartCol; i < pitItemsEndCol; i++) {
        final cell = sheet.getRangeByName('${_getColumnLetter(i)}$row');
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }
    // PIT%, Total Score columns for midterm
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentMidCol - 1)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentMidCol - 1)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentMidCol - 1)}$row')
        .cellStyle
        .vAlign = VAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentMidCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentMidCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentMidCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    // MGA column
    sheet.getRangeByName('${_getColumnLetter(mgaCol)}$row').cellStyle.rotation =
        90;
    sheet.getRangeByName('${_getColumnLetter(mgaCol)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet.getRangeByName('${_getColumnLetter(mgaCol)}$row').cellStyle.vAlign =
        VAlignType.center;

    // Final item columns
    if (fcsItemsEndCol > fcsItemsStartCol) {
      for (int i = fcsItemsStartCol; i < fcsItemsEndCol; i++) {
        final cell = sheet.getRangeByName('${_getColumnLetter(i)}$row');
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }
    // CPA, Total Score columns for final
    sheet
        .getRangeByName('${_getColumnLetter(cpaFinalCol - 1)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(cpaFinalCol - 1)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(cpaFinalCol - 1)}$row')
        .cellStyle
        .vAlign = VAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(cpaFinalCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(cpaFinalCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(cpaFinalCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    if (fqItemsEndCol > fqItemsStartCol) {
      for (int i = fqItemsStartCol; i < fqItemsEndCol; i++) {
        final cell = sheet.getRangeByName('${_getColumnLetter(i)}$row');
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }
    // QA, Total Score columns for final
    sheet
        .getRangeByName('${_getColumnLetter(qaFinalCol - 1)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(qaFinalCol - 1)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(qaFinalCol - 1)}$row')
        .cellStyle
        .vAlign = VAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(qaFinalCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(qaFinalCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(qaFinalCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    if (feItemsEndCol > feItemsStartCol) {
      for (int i = feItemsStartCol; i < feItemsEndCol; i++) {
        final cell = sheet.getRangeByName('${_getColumnLetter(i)}$row');
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }
    // F column
    sheet.getRangeByName('${_getColumnLetter(fCol)}$row').cellStyle.rotation =
        90;
    sheet.getRangeByName('${_getColumnLetter(fCol)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet.getRangeByName('${_getColumnLetter(fCol)}$row').cellStyle.vAlign =
        VAlignType.center;

    if (fpitItemsEndCol > fpitItemsStartCol) {
      for (int i = fpitItemsStartCol; i < fpitItemsEndCol; i++) {
        final cell = sheet.getRangeByName('${_getColumnLetter(i)}$row');
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }
    // PIT%, Total Score columns for final
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentFinalCol - 1)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentFinalCol - 1)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentFinalCol - 1)}$row')
        .cellStyle
        .vAlign = VAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentFinalCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentFinalCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(pitPercentFinalCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    // FGA column
    sheet.getRangeByName('${_getColumnLetter(fgaCol)}$row').cellStyle.rotation =
        90;
    sheet.getRangeByName('${_getColumnLetter(fgaCol)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet.getRangeByName('${_getColumnLetter(fgaCol)}$row').cellStyle.vAlign =
        VAlignType.center;

    // Mid Lec Grade Point, Mid Grade Point, Midterm Grade columns
    sheet
        .getRangeByName('${_getColumnLetter(midLecGradePointCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(midLecGradePointCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(midLecGradePointCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    sheet
        .getRangeByName('${_getColumnLetter(midGradePointCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(midGradePointCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(midGradePointCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    sheet
        .getRangeByName('${_getColumnLetter(midtermGradeCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(midtermGradeCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(midtermGradeCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    // Fin Lec Grade Point, Fin Grade Point, Final Period Grade columns
    sheet
        .getRangeByName('${_getColumnLetter(finLecGradePointCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(finLecGradePointCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(finLecGradePointCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    sheet
        .getRangeByName('${_getColumnLetter(finGradePointCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(finGradePointCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(finGradePointCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    sheet
        .getRangeByName('${_getColumnLetter(finalPeriodGradeCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${_getColumnLetter(finalPeriodGradeCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(finalPeriodGradeCol)}$row')
        .cellStyle
        .vAlign = VAlignType.center;

    // Center all content in row 7
    final row7Range = sheet.getRangeByName(
      'A$row:${_getColumnLetter(totalColumns)}$row',
    );
    row7Range.cellStyle.hAlign = HAlignType.center;
    row7Range.cellStyle.vAlign = VAlignType.center;
    // Disable text wrapping to prevent auto-expansion
    row7Range.cellStyle.wrapText = false;

    // Set row 7 height immediately after setting up content (before Excel recalculates)
    // Row index is 0-based, so row 7 is index 6
    final row7 = sheet.rows[6];
    if (row7 != null) {
      row7.height = 15; // Set to default height to match other rows
    }
  }

  void _writeMaxPointsRow(
    Worksheet sheet,
    int row,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    List<Map<String, dynamic>> midtermExamItems,
    List<Map<String, dynamic>> pitItems,
    List<Map<String, dynamic>> finalClassStandingItems,
    List<Map<String, dynamic>> finalQuizItems,
    List<Map<String, dynamic>> finalExamItems,
    List<Map<String, dynamic>> finalPitItems,
  ) {
    int col = 1;
    // No.
    int noCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('No.');
    // ID Number
    int idCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('ID Number');
    // Names
    int namesCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('Names');

    int csMax = _maxPoints(classStandingItems);
    int csItemsStartCol = col;
    for (var item in classStandingItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int csItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText(csMax.toString());
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');

    int qpMax = _maxPoints(quizPrelimItems);
    int qpItemsStartCol = col;
    for (var item in quizPrelimItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int qpItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText(qpMax.toString());
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');

    int meItemsStartCol = col;
    for (var item in midtermExamItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int meItemsEndCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');

    int pitMax = _maxPoints(pitItems);
    int pitItemsStartCol = col;
    for (var item in pitItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int pitItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText(pitMax.toString());
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');

    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');
    int midLecGradePointMaxCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.000');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.000');
    int midtermGradeMaxCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.00');

    int fcsMax = _maxPoints(finalClassStandingItems);
    int fcsItemsStartCol = col;
    for (var item in finalClassStandingItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int fcsItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText(fcsMax.toString());
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');

    int fqMax = _maxPoints(finalQuizItems);
    int fqItemsStartCol = col;
    for (var item in finalQuizItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int fqItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText(fqMax.toString());
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');

    int feItemsStartCol = col;
    for (var item in finalExamItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int feItemsEndCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');

    int fpitMax = _maxPoints(finalPitItems);
    int fpitItemsStartCol = col;
    for (var item in finalPitItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int fpitItemsEndCol = col;
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText(fpitMax.toString());
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');

    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('100%');
    int finLecGradePointMaxCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.000');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.000');
    int finalPeriodGradeMaxCol = col;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.00');

    // Computed section defaults
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('Excellent');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('Excellent');

    final rowRange = sheet.getRangeByName(
      'A$row:${_getColumnLetter(col - 1)}$row',
    );
    rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
    rowRange.cellStyle.backColor = '#FFFFFF'; // White background
    rowRange.cellStyle.fontColor = '#333399'; // Foreground text color

    // Style No., ID Number, and Names columns: BOLD, white background, black foreground
    sheet.getRangeByName('${_getColumnLetter(noCol)}$row').cellStyle.bold =
        true;
    sheet.getRangeByName('${_getColumnLetter(noCol)}$row').cellStyle.backColor =
        '#FFFFFF';
    sheet.getRangeByName('${_getColumnLetter(noCol)}$row').cellStyle.fontColor =
        '#000000';

    sheet.getRangeByName('${_getColumnLetter(idCol)}$row').cellStyle.bold =
        true;
    sheet.getRangeByName('${_getColumnLetter(idCol)}$row').cellStyle.backColor =
        '#FFFFFF';
    sheet.getRangeByName('${_getColumnLetter(idCol)}$row').cellStyle.fontColor =
        '#000000';

    sheet.getRangeByName('${_getColumnLetter(namesCol)}$row').cellStyle.bold =
        true;
    sheet
        .getRangeByName('${_getColumnLetter(namesCol)}$row')
        .cellStyle
        .backColor = '#FFFFFF';
    sheet
        .getRangeByName('${_getColumnLetter(namesCol)}$row')
        .cellStyle
        .fontColor = '#000000';

    // Make all max points numbers bold (starting from column 4, after No., ID Number, Names)
    final numbersRange = sheet.getRangeByName(
      '${_getColumnLetter(4)}$row:${_getColumnLetter(col - 1)}$row',
    );
    numbersRange.cellStyle.bold = true;

    // Apply white background to item columns (assignments, quizzes, etc.)
    if (csItemsEndCol > csItemsStartCol) {
      final csItemsRange = sheet.getRangeByName(
        '${_getColumnLetter(csItemsStartCol)}$row:${_getColumnLetter(csItemsEndCol - 1)}$row',
      );
      csItemsRange.cellStyle.backColor = '#FFFFFF';
    }
    if (qpItemsEndCol > qpItemsStartCol) {
      final qpItemsRange = sheet.getRangeByName(
        '${_getColumnLetter(qpItemsStartCol)}$row:${_getColumnLetter(qpItemsEndCol - 1)}$row',
      );
      qpItemsRange.cellStyle.backColor = '#FFFFFF';
    }
    if (meItemsEndCol > meItemsStartCol) {
      final meItemsRange = sheet.getRangeByName(
        '${_getColumnLetter(meItemsStartCol)}$row:${_getColumnLetter(meItemsEndCol - 1)}$row',
      );
      meItemsRange.cellStyle.backColor = '#FFFFFF';
    }
    if (pitItemsEndCol > pitItemsStartCol) {
      final pitItemsRange = sheet.getRangeByName(
        '${_getColumnLetter(pitItemsStartCol)}$row:${_getColumnLetter(pitItemsEndCol - 1)}$row',
      );
      pitItemsRange.cellStyle.backColor = '#FFFFFF';
    }
    if (fcsItemsEndCol > fcsItemsStartCol) {
      final fcsItemsRange = sheet.getRangeByName(
        '${_getColumnLetter(fcsItemsStartCol)}$row:${_getColumnLetter(fcsItemsEndCol - 1)}$row',
      );
      fcsItemsRange.cellStyle.backColor = '#FFFFFF';
    }
    if (fqItemsEndCol > fqItemsStartCol) {
      final fqItemsRange = sheet.getRangeByName(
        '${_getColumnLetter(fqItemsStartCol)}$row:${_getColumnLetter(fqItemsEndCol - 1)}$row',
      );
      fqItemsRange.cellStyle.backColor = '#FFFFFF';
    }
    if (feItemsEndCol > feItemsStartCol) {
      final feItemsRange = sheet.getRangeByName(
        '${_getColumnLetter(feItemsStartCol)}$row:${_getColumnLetter(feItemsEndCol - 1)}$row',
      );
      feItemsRange.cellStyle.backColor = '#FFFFFF';
    }
    if (fpitItemsEndCol > fpitItemsStartCol) {
      final fpitItemsRange = sheet.getRangeByName(
        '${_getColumnLetter(fpitItemsStartCol)}$row:${_getColumnLetter(fpitItemsEndCol - 1)}$row',
      );
      fpitItemsRange.cellStyle.backColor = '#FFFFFF';
    }

    // Apply #C6E0B4 background to Mid Lec Grade Point and Fin Lec Grade Point columns
    sheet
        .getRangeByName('${_getColumnLetter(midLecGradePointMaxCol)}$row')
        .cellStyle
        .backColor = '#C6E0B4';
    sheet
        .getRangeByName('${_getColumnLetter(finLecGradePointMaxCol)}$row')
        .cellStyle
        .backColor = '#C6E0B4';

    // Apply #FFC000 background to Midterm Grade and Final Period Grade columns
    sheet
        .getRangeByName('${_getColumnLetter(midtermGradeMaxCol)}$row')
        .cellStyle
        .backColor = '#FFC000';
    sheet
        .getRangeByName('${_getColumnLetter(finalPeriodGradeMaxCol)}$row')
        .cellStyle
        .backColor = '#FFC000';

    // Center all content in row 8 (max points row)
    final totalColumns = col - 1;
    final row8Range = sheet.getRangeByName(
      'A$row:${_getColumnLetter(totalColumns)}$row',
    );
    row8Range.cellStyle.hAlign = HAlignType.center;
    row8Range.cellStyle.vAlign = VAlignType.center;
  }

  // Helpers used by the full export (mirror grid logic)
  String _makeItemKey(Map<String, dynamic> item) {
    return '${(item['title'] ?? '').toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
  }

  String _readScore(Map<String, dynamic> student, String key) {
    return (student[key]?.toString() ?? '');
  }

  int _maxPoints(List<Map<String, dynamic>> items) {
    return items.fold(
      0,
      (sum, it) => sum + ((it['points'] ?? 0) as num).toInt(),
    );
  }

  int _calculateGroupTotal(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> items,
  ) {
    int total = 0;
    for (var item in items) {
      final key = _makeItemKey(item);
      final v = int.tryParse(student[key]?.toString() ?? '0');
      if (v != null) total += v;
    }
    return total;
  }

  double _calculateGroupPercent(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> items,
  ) {
    final total = _calculateGroupTotal(student, items);
    final maxTotal = _maxPoints(items);
    if (maxTotal == 0) return 0.0;
    return (total / maxTotal) * 100.0;
  }

  double _fraction(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> items,
  ) {
    final maxTotal = _maxPoints(items);
    if (maxTotal == 0) return 0.0;
    final total = _calculateGroupTotal(student, items);
    return total / maxTotal;
  }

  double _calculateRawMGAFromGroups(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> cs,
    List<Map<String, dynamic>> qp,
    List<Map<String, dynamic>> exam,
    List<Map<String, dynamic>> pit,
  ) {
    final cpa = _fraction(student, cs);
    final qa = _fraction(student, qp);
    final ex = _fraction(student, exam);
    final p = _fraction(student, pit);
    return 0.10 * cpa + 0.40 * qa + 0.30 * ex + 0.20 * p;
  }

  double _gradePointFromRatio(double ratio) {
    if (ratio >= 0.7) {
      return (23.0 / 3.0) - (20.0 / 3.0) * ratio;
    } else {
      return 5.0 - (20.0 / 7.0) * ratio;
    }
  }

  String _mapGradePointToEquivalent(double gradePoint) {
    final gp = double.parse(gradePoint.toStringAsFixed(3));
    for (final range in _midtermGradeIntervals) {
      if (gp >= range[0] && gp < range[1]) {
        return range[2].toStringAsFixed(2);
      }
    }
    return '5.00';
  }

  double _mapGradePointToEquivalentAsNumber(double gradePoint) {
    return double.tryParse(_mapGradePointToEquivalent(gradePoint)) ?? 5.00;
  }

  double _gradeLadder(double numericGrade) {
    final gp = double.parse(numericGrade.toStringAsFixed(3));
    for (final range in _midtermGradeIntervals) {
      if (gp >= range[0] && gp < range[1]) {
        return range[2];
      }
    }
    return 5.00;
  }

  String _descFromNumeric(double numGrade) {
    if (numGrade <= 1.00) return 'Excellent';
    if (numGrade <= 2.99) return 'Passed';
    return 'Failed';
  }

  // Reuse the same intervals used in the grid for grade mapping
  static const List<List<double>> _midtermGradeIntervals = [
    [1.000, 1.125, 1.00],
    [1.125, 1.375, 1.25],
    [1.375, 1.625, 1.50],
    [1.625, 1.875, 1.75],
    [1.875, 2.125, 2.00],
    [2.125, 2.375, 2.25],
    [2.375, 2.625, 2.50],
    [2.625, 2.875, 2.75],
    [2.875, 3.125, 3.00],
    [3.125, 3.375, 3.25],
    [3.375, 3.625, 3.50],
    [3.625, 3.875, 3.75],
    [3.875, 4.125, 4.00],
    [4.125, 4.375, 4.25],
    [4.375, 4.625, 4.50],
    [4.625, 4.875, 4.75],
    [4.875, 5.125, 5.00],
  ];

  int _totalColumnCount(
    List<Map<String, dynamic>> cs,
    List<Map<String, dynamic>> qp,
    List<Map<String, dynamic>> me,
    List<Map<String, dynamic>> pit,
    List<Map<String, dynamic>> fcs,
    List<Map<String, dynamic>> fq,
    List<Map<String, dynamic>> fe,
    List<Map<String, dynamic>> fpit,
  ) {
    // No, ID, Names
    int count = 3;
    count += cs.length + 2; // items + SRC + CPA
    count += qp.length + 2; // items + SRQ + QA
    count += me.length + 1; // items + M
    count += pit.length + 2; // items + PIT total + PIT%
    count += 4; // MGA + Mid Lec + Mid GP + Midterm Grade
    count += fcs.length + 2; // final cs + SRC + CPA
    count += fq.length + 2; // final quiz + SRQ + QA
    count += fe.length + 1; // final exam + F
    count += fpit.length + 2; // final pit + total + %
    count += 4; // FGA + Fin Lec + Fin GP + Final Period Grade
    count += 8; // computed 8 cols
    return count;
  }

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
      _setupStudentListHeaders(sheet, sectionName, courseName, instructorName);

      // Add student data
      _addStudentListData(sheet, students);

      // Auto-fit columns
      _autoFitColumns(sheet);

      // Save and open file
      await _saveAndOpenFile(workbook, '${sectionName}_StudentList');
    } catch (e) {
      Get.snackbar(
        'Export Error',
        'Failed to export student list: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
      print('🔍 Starting grade sheet export...');
      print('📊 Students: ${students.length}');
      print('📋 Class Standing Items: ${classStandingItems.length}');
      print('📋 Quiz/Prelim Items: ${quizPrelimItems.length}');

      // Create a new Excel workbook
      print('📝 Creating Excel workbook...');
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Grade Sheet';

      // Set up complete headers
      print('📋 Setting up headers...');
      _setupGradeSheetHeaders(
        sheet,
        classStandingItems,
        quizPrelimItems,
        sectionName,
        courseName,
        instructorName,
        departmentName,
      );

      // Add student data with scores
      print('👥 Adding student data...');
      await _addGradeSheetData(
        sheet,
        students,
        classStandingItems,
        quizPrelimItems,
      );

      // Auto-fit columns
      print('📏 Auto-fitting columns...');
      _autoFitColumns(sheet);

      // Save and open file
      print('💾 Saving file...');
      await _saveAndOpenFile(workbook, '${sectionName}_GradeSheet');
      print('✅ Grade sheet export completed!');
    } catch (e) {
      print('❌ Grade sheet export error: $e');
      Get.snackbar(
        'Export Error',
        'Failed to export grade sheet: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Set up headers for student list export
  void _setupStudentListHeaders(
    Worksheet sheet,
    String sectionName,
    String courseName,
    String instructorName,
  ) {
    int row = 1;

    // Title
    sheet.getRangeByName('A$row:Z$row').merge();
    sheet.getRangeByName('A$row').setText('STUDENT LIST');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    sheet.getRangeByName('A$row').cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A$row').cellStyle.backColor = '#E3F2FD';
    row++;

    // Section info
    sheet.getRangeByName('A$row').setText('Section: $sectionName');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    row++;

    sheet.getRangeByName('A$row').setText('Course: $courseName');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    row++;

    // Move to row 10 for headers
    row = 10;

    // Column headers
    sheet.getRangeByName('A$row').setText('No.');
    sheet.getRangeByName('B$row').setText('ID Number');
    sheet.getRangeByName('C$row').setText('Student Name');
    sheet.getRangeByName('D$row').setText('Email');
    sheet.getRangeByName('E$row').setText('Status');

    // Style headers
    final headerRange = sheet.getRangeByName('A$row:E$row');
    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.backColor = '#FFFFFF';
    headerRange.cellStyle.fontColor = '#000000';
    headerRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
  }

  /// Set up complete headers for grade sheet export
  void _setupGradeSheetHeaders(
    Worksheet sheet,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    String sectionName,
    String courseName,
    String instructorName,
    String departmentName,
  ) {
    int row = 1;

    // Calculate total columns
    int totalColumns =
        3 +
        classStandingItems.length +
        2 +
        2; // No, ID Number, Names + class standing + SRC, CPA + SRQ, QA

    // Row 1: MIDTERM GRADE (merged across all columns)
    sheet.getRangeByName('A$row:${_getColumnLetter(totalColumns)}$row').merge();
    sheet.getRangeByName('A$row').setText('MIDTERM GRADE');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    sheet.getRangeByName('A$row').cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A$row').cellStyle.backColor = '#99CCFF'; // Light blue
    row++;

    // Row 2: LECTURE 100% (merged across all columns)
    sheet.getRangeByName('A$row:${_getColumnLetter(totalColumns)}$row').merge();
    sheet.getRangeByName('A$row').setText('LECTURE 100%');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    sheet.getRangeByName('A$row').cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A$row').cellStyle.backColor = '#FFC000'; // Orange
    row++;

    // Row 3: Performance Categories
    int classStandingCols = classStandingItems.length + 2; // items + SRC + CPA
    int quizPrelimCols = 2; // Only SRQ + QA (no individual items)
    int startCol = 4; // After No, ID Number, Names

    // Class Standing Performance Items
    sheet
        .getRangeByName(
          '${_getColumnLetter(startCol)}$row:${_getColumnLetter(startCol + classStandingCols - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(startCol)}$row')
        .setText('CLASS STANDING PERFORMANCE ITEMS (10%)');
    sheet.getRangeByName('${_getColumnLetter(startCol)}$row').cellStyle.bold =
        true;
    sheet.getRangeByName('${_getColumnLetter(startCol)}$row').cellStyle.hAlign =
        HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(startCol)}$row')
        .cellStyle
        .backColor = '#FCF305'; // Yellow

    // Quiz/Prelim Performance Item
    int quizStartCol = startCol + classStandingCols;
    sheet
        .getRangeByName(
          '${_getColumnLetter(quizStartCol)}$row:${_getColumnLetter(quizStartCol + quizPrelimCols - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${_getColumnLetter(quizStartCol)}$row')
        .setText('PRELIM PERFORMANCE ITEM');
    sheet
        .getRangeByName('${_getColumnLetter(quizStartCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${_getColumnLetter(quizStartCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${_getColumnLetter(quizStartCol)}$row')
        .cellStyle
        .backColor = '#FCF305'; // Yellow
    row++;

    // Row 4: Department and Subject Info
    sheet
        .getRangeByName('A$row')
        .setText('Department of NATIONAL SERVICE TRAINING PROGRAM');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    row++;

    sheet.getRangeByName('A$row').setText('Subject: NSTP 101C');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    row++;

    sheet.getRangeByName('A$row').setText('Section: $sectionName');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    row++;

    sheet.getRangeByName('A$row').setText('Course: $courseName');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    row++;

    // Row 10: Column Headers
    int col = 1;
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('No.');
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('ID Number'); // Swapped position
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Names'); // Swapped position

    // Class Standing Items
    for (var item in classStandingItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['title'] ?? 'Unknown');
    }
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Total Score (SRC)');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('CPA');

    // Quiz/Prelim Items (only totals, no individual items)
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('Total Score (SRQ)');
    sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText('QA');

    // Style headers
    final headerRange = sheet.getRangeByName(
      'A$row:${_getColumnLetter(totalColumns)}$row',
    );
    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.backColor = '#F8FAFB';
    headerRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
    row++;

    // Row 11: Max Points
    col = 4; // Start after No, ID Number, Names
    for (var item in classStandingItems) {
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(item['points']?.toString() ?? '');
    }
    // Calculate actual SRC total from class standing items
    double srcTotal = 0;
    for (var item in classStandingItems) {
      srcTotal += (item['points'] ?? 0).toDouble();
    }
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText(srcTotal.toString()); // SRC total
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('100%'); // CPA

    // Quiz/Prelim max points (only totals)
    // Calculate actual SRQ total from quiz/prelim items
    double srqTotal = 0;
    for (var item in quizPrelimItems) {
      srqTotal += (item['points'] ?? 0).toDouble();
    }
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText(srqTotal.toString()); // SRQ total
    sheet
        .getRangeByName('${_getColumnLetter(col++)}$row')
        .setText('100%'); // QA
  }

  /// Add student data to grade sheet
  Future<void> _addGradeSheetData(
    Worksheet sheet,
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
  ) async {
    int dataStartRow = 10; // Start user data at row 10

    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      int row = dataStartRow + i;
      int col = 1;

      // Basic student info
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setNumber(i + 1); // No.
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(student['idNumber'] ?? ''); // ID Number (swapped position)
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(
            _formatStudentName(student['name'] ?? ''),
          ); // Student Name (formatted) - swapped position

      // Get student scores
      Map<String, dynamic> studentScores = await _getStudentScores(
        student['id'] ?? '',
        classStandingItems,
        quizPrelimItems,
      );

      // Class Standing scores
      for (var item in classStandingItems) {
        String key =
            '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
        String score = studentScores[key]?.toString() ?? '';
        sheet.getRangeByName('${_getColumnLetter(col++)}$row').setText(score);
      }

      // Calculate and add SRC and CPA
      double src = _calculateSRC(studentScores, classStandingItems);
      double cpa = _calculateCPA(src, classStandingItems);
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(src.toString());
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText('${cpa.toStringAsFixed(1)}%');

      // Quiz/Prelim scores (only totals, no individual items)
      // Calculate and add SRQ and QA
      double srq = _calculateSRQ(studentScores, quizPrelimItems);
      double qa = _calculateQA(srq, quizPrelimItems);
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText(srq.toString());
      sheet
          .getRangeByName('${_getColumnLetter(col++)}$row')
          .setText('${qa.toStringAsFixed(1)}%');

      // Add borders to row
      final rowRange = sheet.getRangeByName(
        'A$row:${_getColumnLetter(col - 1)}$row',
      );
      rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
  }

  /// Add student data to student list
  void _addStudentListData(
    Worksheet sheet,
    List<Map<String, dynamic>> students,
  ) {
    int dataStartRow = 11; // After headers

    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      int row = dataStartRow + i;

      sheet.getRangeByName('A$row').setNumber(i + 1);
      sheet
          .getRangeByName('B$row')
          .setText(
            student['idNumber'] ?? '',
          ); // ID Number (already in correct position)
      sheet
          .getRangeByName('C$row')
          .setText(
            _formatStudentName(student['name'] ?? ''),
          ); // Student Name (already in correct position)
      sheet.getRangeByName('D$row').setText(student['email'] ?? '');
      sheet.getRangeByName('E$row').setText(student['enrollmentStatus'] ?? '');

      // Add borders to row
      final rowRange = sheet.getRangeByName('A$row:E$row');
      rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
  }

  /// Get student scores from database
  Future<Map<String, dynamic>> _getStudentScores(
    String studentId,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
  ) async {
    Map<String, dynamic> scores = {};

    try {
      final user = _auth.currentUser;
      if (user == null) return scores;

      // Get scores for class standing items
      for (var item in classStandingItems) {
        String itemType =
            item['type']?.toString().toLowerCase() ?? 'assignment';
        String collection = _getCollectionName(itemType);
        String idField = _getIdFieldName(itemType);

        final query =
            await _firestore
                .collection(collection)
                .where('studentId', isEqualTo: studentId)
                .where(idField, isEqualTo: item['id'])
                .where('status', isEqualTo: 'graded')
                .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          String key =
              '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
          scores[key] = data['grade'] ?? 0;
        }
      }

      // Get scores for quiz/prelim items
      for (var item in quizPrelimItems) {
        String itemType = item['type']?.toString().toLowerCase() ?? 'quiz';
        String collection = _getCollectionName(itemType);
        String idField = _getIdFieldName(itemType);

        final query =
            await _firestore
                .collection(collection)
                .where('studentId', isEqualTo: studentId)
                .where(idField, isEqualTo: item['id'])
                .where('status', isEqualTo: 'graded')
                .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          String key =
              '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
          scores[key] = data['grade'] ?? 0;
        }
      }
    } catch (e) {
      print('Error getting student scores: $e');
    }

    return scores;
  }

  /// Calculate SRC (Student Raw Score for Class Standing)
  double _calculateSRC(
    Map<String, dynamic> scores,
    List<Map<String, dynamic>> items,
  ) {
    double total = 0;
    for (var item in items) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      total += (scores[key] ?? 0).toDouble();
    }
    return total;
  }

  /// Calculate CPA (Class Performance Average)
  double _calculateCPA(double src, List<Map<String, dynamic>> items) {
    double maxTotal = 0;
    for (var item in items) {
      maxTotal += (item['points'] ?? 0).toDouble();
    }
    if (maxTotal == 0) return 0;
    return (src / maxTotal) * 100;
  }

  /// Calculate SRQ (Student Raw Score for Quiz/Prelim)
  double _calculateSRQ(
    Map<String, dynamic> scores,
    List<Map<String, dynamic>> items,
  ) {
    double total = 0;
    for (var item in items) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      total += (scores[key] ?? 0).toDouble();
    }
    return total;
  }

  /// Calculate QA (Quiz Average)
  double _calculateQA(double srq, List<Map<String, dynamic>> items) {
    double maxTotal = 0;
    for (var item in items) {
      maxTotal += (item['points'] ?? 0).toDouble();
    }
    if (maxTotal == 0) return 0;
    return (srq / maxTotal) * 100;
  }

  /// Get collection name based on item type
  String _getCollectionName(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'assignment':
        return 'assignment_submissions';
      case 'activity':
        return 'activity_submissions';
      case 'quiz':
        return 'quiz_submissions';
      case 'pit':
        return 'submissions';
      default:
        return 'assignment_submissions';
    }
  }

  /// Get ID field name based on item type
  String _getIdFieldName(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'assignment':
        return 'assignmentId';
      case 'activity':
        return 'activityId';
      case 'quiz':
        return 'quizId';
      case 'pit':
        return 'pitId';
      default:
        return 'assignmentId';
    }
  }

  /// Auto-fit columns
  void _autoFitColumns(Worksheet sheet) {
    for (int i = 1; i <= sheet.getLastColumn(); i++) {
      sheet.autoFitColumn(i);
    }
  }

  /// Get column letter from number (1 = A, 2 = B, etc.)
  String _getColumnLetter(int columnNumber) {
    String result = '';
    while (columnNumber > 0) {
      columnNumber--;
      result = String.fromCharCode(65 + (columnNumber % 26)) + result;
      columnNumber ~/= 26;
    }
    return result;
  }

  /// Save workbook and download file (Web-compatible)
  Future<void> _saveAndOpenFile(Workbook workbook, String fileName) async {
    try {
      print('🔍 Starting web file download...');

      // Create filename with timestamp
      final now = DateTime.now();
      final timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final fullFileName = '${fileName}_$timestamp.xlsx';

      print('📄 Filename: $fullFileName');

      // Generate Excel bytes
      print('💾 Generating Excel bytes...');
      final List<int> bytes = workbook.saveAsStream();
      print('💾 Excel bytes generated: ${bytes.length} bytes');

      // Convert to Uint8List for web download
      final Uint8List uint8List = Uint8List.fromList(bytes);

      // Create blob and download
      print('🌐 Creating blob and triggering download...');
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
      print('🗑️ Workbook disposed');

      // Show success message
      Get.snackbar(
        'Export Successful',
        'File downloaded: $fullFileName',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      print('✅ Web download completed!');
    } catch (e) {
      print('❌ Web export error: $e');
      Get.snackbar(
        'Export Error',
        'Failed to download file: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
