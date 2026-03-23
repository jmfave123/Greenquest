import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'excel_style_constants.dart';
import 'excel_column_layout.dart';
import 'excel_header_builder.dart';
import 'grade_calculator.dart';

class ExcelStudentDataWriter {
  static void writeCompleteClassRecordData(
    Worksheet sheet,
    int startRow,
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    List<Map<String, dynamic>> midtermExamItems,
    List<Map<String, dynamic>> pitItems,
    List<Map<String, dynamic>> finalClassStandingItems,
    List<Map<String, dynamic>> finalQuizItems,
    List<Map<String, dynamic>> finalExamItems,
    List<Map<String, dynamic>> finalPitItems,
    GradeCalculator gradeCalc,
  ) {
    // Write students
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final row = startRow + 1 + i;
      int col = 1;

      // No, ID, Names
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setNumber(i + 1);
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(student['idNumber'] ?? '');
      // Name column (column C) - set to left align and uppercase
      final nameCell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      nameCell.setText(gradeCalc.formatStudentName(student['name'] ?? ''));
      nameCell.cellStyle.hAlign = HAlignType.left;

      // Class Standing items
      int csItemsStartCol = col;
      for (var item in classStandingItems) {
        final key = gradeCalc.makeItemKey(item);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(gradeCalc.readScore(student, key));
      }
      int csItemsEndCol = col;
      // Total (SRC) and CPA
      final csTotal = gradeCalc.calculateGroupTotal(
        student,
        classStandingItems,
      );
      final csPct = gradeCalc.calculateGroupPercent(
        student,
        classStandingItems,
      );
      int srcMidCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(csTotal.toString());
      int cpaMidCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${csPct.round()}%');

      // Quiz/Prelim items
      int qpItemsStartCol = col;
      for (var item in quizPrelimItems) {
        final key = gradeCalc.makeItemKey(item);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(gradeCalc.readScore(student, key));
      }
      int qpItemsEndCol = col;
      final qpTotal = gradeCalc.calculateGroupTotal(student, quizPrelimItems);
      final qpPct = gradeCalc.calculateGroupPercent(student, quizPrelimItems);
      int srqMidCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(qpTotal.toString());
      int qaMidCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${qpPct.round()}%');

      // Midterm Exam items
      int meItemsStartCol = col;
      for (var item in midtermExamItems) {
        final key = gradeCalc.makeItemKey(item);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(gradeCalc.readScore(student, key));
      }
      int meItemsEndCol = col;
      final mPct = gradeCalc.calculateGroupPercent(student, midtermExamItems);
      int mCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${mPct.round()}%');

      // PIT items
      int pitItemsStartCol = col;
      for (var item in pitItems) {
        final key = gradeCalc.makeItemKey(item);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(gradeCalc.readScore(student, key));
      }
      int pitItemsEndCol = col;
      final pitTotal = gradeCalc.calculateGroupTotal(student, pitItems);
      final pitPct = gradeCalc.calculateGroupPercent(student, pitItems);
      int pitTotalMidCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(pitTotal.toString());
      int pitPercentMidCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${pitPct.round()}%');

      // Lecture (Midterm)
      final mga = gradeCalc.calculateRawMGA(
        student,
        classStandingItems,
        quizPrelimItems,
        midtermExamItems,
        pitItems,
      );
      int mgaCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${(mga * 100).round()}%');
      final midLec = gradeCalc.gradePointFromRatio(mga);
      int midLecGradePointCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(midLec.toStringAsFixed(3));
      int midGradePointCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(midLec.toStringAsFixed(3));
      int midtermGradeDataCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(gradeCalc.mapGradePointToEquivalent(midLec));

      // Final Class Standing items
      int fcsItemsStartCol = col;
      for (var item in finalClassStandingItems) {
        final key = gradeCalc.makeItemKey(item);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(gradeCalc.readScore(student, key));
      }
      int fcsItemsEndCol = col;
      final fcsTotal = gradeCalc.calculateGroupTotal(
        student,
        finalClassStandingItems,
      );
      final fcsPct = gradeCalc.calculateGroupPercent(
        student,
        finalClassStandingItems,
      );
      int srcFinalCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(fcsTotal.toString());
      int cpaFinalCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${fcsPct.round()}%');

      // Final Quiz items
      int fqItemsStartCol = col;
      for (var item in finalQuizItems) {
        final key = gradeCalc.makeItemKey(item);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(gradeCalc.readScore(student, key));
      }
      int fqItemsEndCol = col;
      final fqTotal = gradeCalc.calculateGroupTotal(student, finalQuizItems);
      final fqPct = gradeCalc.calculateGroupPercent(student, finalQuizItems);
      int srqFinalCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(fqTotal.toString());
      int qaFinalCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${fqPct.round()}%');

      // Final Exam items
      int feItemsStartCol = col;
      for (var item in finalExamItems) {
        final key = gradeCalc.makeItemKey(item);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(gradeCalc.readScore(student, key));
      }
      int feItemsEndCol = col;
      final fPct = gradeCalc.calculateGroupPercent(student, finalExamItems);
      int fCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${fPct.round()}%');

      // Final PIT items
      int fpitItemsStartCol = col;
      for (var item in finalPitItems) {
        final key = gradeCalc.makeItemKey(item);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(gradeCalc.readScore(student, key));
      }
      int fpitItemsEndCol = col;
      final fpitTotal = gradeCalc.calculateGroupTotal(student, finalPitItems);
      final fpitPct = gradeCalc.calculateGroupPercent(student, finalPitItems);
      int pitTotalFinalCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(fpitTotal.toString());
      int pitPercentFinalCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${fpitPct.round()}%');

      // Final Lecture
      final fga = gradeCalc.calculateRawMGA(
        student,
        finalClassStandingItems,
        finalQuizItems,
        finalExamItems,
        finalPitItems,
      );
      int fgaCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${(fga * 100).round()}%');
      final finLec = gradeCalc.gradePointFromRatio(fga);
      int finLecGradePointCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(finLec.toStringAsFixed(3));
      int finGradePointCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(finLec.toStringAsFixed(3));
      final ftg = gradeCalc.mapGradePointToEquivalent(finLec);
      int finalPeriodGradeDataCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(ftg);

      // Computed Final Grade section
      final mtg = gradeCalc.mapGradePointToEquivalentAsNumber(midLec);
      final ftgNum = gradeCalc.mapGradePointToEquivalentAsNumber(finLec);

      double comp12 = 0.5 * mtg + 0.5 * ftgNum;
      double comp13 = (1.0 / 3.0) * mtg + (2.0 / 3.0) * ftgNum;

      // 1/2 MTG + 1/2 FTG
      int comp12Col = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(comp12.toStringAsFixed(2));
      // For Removal (cap > 3.50 -> 5.00)
      final comp12Mapped = gradeCalc.gradeLadder(comp12);
      int comp12RemovalCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(
            comp12Mapped > 3.50 ? '5.00' : comp12Mapped.toStringAsFixed(2),
          );
      // After Removal (copy For Removal)
      int comp12AfterCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(
            comp12Mapped > 3.50 ? '5.00' : comp12Mapped.toStringAsFixed(2),
          );
      // Description
      int comp12DescCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(gradeCalc.descFromNumeric(comp12));

      // 1/3 MTG + 2/3 FTG
      int comp13Col = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(comp13.toStringAsFixed(2));
      final comp13Mapped = gradeCalc.gradeLadder(comp13);
      int comp13RemovalCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(
            comp13Mapped > 3.50 ? '5.00' : comp13Mapped.toStringAsFixed(2),
          );
      int comp13AfterCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(
            comp13Mapped > 3.50 ? '5.00' : comp13Mapped.toStringAsFixed(2),
          );
      int comp13DescCol = col;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(gradeCalc.descFromNumeric(comp13));

      // Row borders
      final rowRange = sheet.getRangeByName(
        'A$row:${ExcelColumnLayout.getColumnLetter(col - 1)}$row',
      );
      rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      // Apply bold and foreground color #333399 to Total Score, CPA, QA, M, PIT%, MGA (both midterm and final)
      // Midterm columns
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(srcMidCol)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(srcMidCol)}$row')
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaMidCol)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaMidCol)}$row')
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(srqMidCol)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(srqMidCol)}$row')
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaMidCol)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaMidCol)}$row')
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(mCol)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(mCol)}$row')
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(pitTotalMidCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(pitTotalMidCol)}$row',
          )
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol)}$row',
          )
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(mgaCol)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(mgaCol)}$row')
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      // Final columns
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(srcFinalCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(srcFinalCol)}$row',
          )
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(cpaFinalCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(cpaFinalCol)}$row',
          )
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(srqFinalCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(srqFinalCol)}$row',
          )
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(qaFinalCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(qaFinalCol)}$row',
          )
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(fCol)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(fCol)}$row')
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(pitTotalFinalCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(pitTotalFinalCol)}$row',
          )
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol)}$row',
          )
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(fgaCol)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(fgaCol)}$row')
          .cellStyle
          .fontColor = ExcelStyleConstants.kSummaryFontColor;

      // Apply white background to item columns (assignments, quizzes, etc.)
      if (csItemsEndCol > csItemsStartCol) {
        final csItemsRange = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(csItemsStartCol)}$row:${ExcelColumnLayout.getColumnLetter(csItemsEndCol - 1)}$row',
        );
        csItemsRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
      }
      if (qpItemsEndCol > qpItemsStartCol) {
        final qpItemsRange = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(qpItemsStartCol)}$row:${ExcelColumnLayout.getColumnLetter(qpItemsEndCol - 1)}$row',
        );
        qpItemsRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
      }
      if (meItemsEndCol > meItemsStartCol) {
        final meItemsRange = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(meItemsStartCol)}$row:${ExcelColumnLayout.getColumnLetter(meItemsEndCol - 1)}$row',
        );
        meItemsRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
      }
      if (pitItemsEndCol > pitItemsStartCol) {
        final pitItemsRange = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitItemsStartCol)}$row:${ExcelColumnLayout.getColumnLetter(pitItemsEndCol - 1)}$row',
        );
        pitItemsRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
      }
      if (fcsItemsEndCol > fcsItemsStartCol) {
        final fcsItemsRange = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(fcsItemsStartCol)}$row:${ExcelColumnLayout.getColumnLetter(fcsItemsEndCol - 1)}$row',
        );
        fcsItemsRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
      }
      if (fqItemsEndCol > fqItemsStartCol) {
        final fqItemsRange = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(fqItemsStartCol)}$row:${ExcelColumnLayout.getColumnLetter(fqItemsEndCol - 1)}$row',
        );
        fqItemsRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
      }
      if (feItemsEndCol > feItemsStartCol) {
        final feItemsRange = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(feItemsStartCol)}$row:${ExcelColumnLayout.getColumnLetter(feItemsEndCol - 1)}$row',
        );
        feItemsRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
      }
      if (fpitItemsEndCol > fpitItemsStartCol) {
        final fpitItemsRange = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(fpitItemsStartCol)}$row:${ExcelColumnLayout.getColumnLetter(fpitItemsEndCol - 1)}$row',
        );
        fpitItemsRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
      }

      // Apply #C6E0B4 background to Mid Lec Grade Point and Fin Lec Grade Point columns
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(midLecGradePointCol)}$row',
          )
          .cellStyle
          .backColor = ExcelStyleConstants.kComputedGreenBg;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(finLecGradePointCol)}$row',
          )
          .cellStyle
          .backColor = ExcelStyleConstants.kComputedGreenBg;

      // Apply #FFC000 background to Midterm Grade and Final Period Grade columns
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(midtermGradeDataCol)}$row',
          )
          .cellStyle
          .backColor = ExcelStyleConstants.kHeaderOrangeBg;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(finalPeriodGradeDataCol)}$row',
          )
          .cellStyle
          .backColor = ExcelStyleConstants.kHeaderOrangeBg;

      // Apply bold and conditional color to Mid Lec Grade Point, Mid Grade Point, Midterm Grade values
      // Green if passing (<= 3.00), Red if failing (> 3.00)
      double midLecValue = double.tryParse(midLec.toStringAsFixed(3)) ?? 5.00;
      String midLecColor =
          midLecValue <= 3.00
              ? ExcelStyleConstants.kPassingGreen
              : ExcelStyleConstants.kFailingRed;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(midLecGradePointCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(midLecGradePointCol)}$row',
          )
          .cellStyle
          .fontColor = midLecColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(midGradePointCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(midGradePointCol)}$row',
          )
          .cellStyle
          .fontColor = midLecColor;

      double midtermGradeValue =
          double.tryParse(gradeCalc.mapGradePointToEquivalent(midLec)) ?? 5.00;
      String midtermGradeColor =
          midtermGradeValue <= 3.00
              ? ExcelStyleConstants.kPassingGreen
              : ExcelStyleConstants.kFailingRed;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(midtermGradeDataCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(midtermGradeDataCol)}$row',
          )
          .cellStyle
          .fontColor = midtermGradeColor;

      // Apply bold and conditional color to Fin Lec Grade Point, Fin Grade Point, Final Period Grade values
      // Green if passing (<= 3.00), Red if failing (> 3.00)
      double finLecValue = double.tryParse(finLec.toStringAsFixed(3)) ?? 5.00;
      String finLecColor =
          finLecValue <= 3.00
              ? ExcelStyleConstants.kPassingGreen
              : ExcelStyleConstants.kFailingRed;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(finLecGradePointCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(finLecGradePointCol)}$row',
          )
          .cellStyle
          .fontColor = finLecColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(finGradePointCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(finGradePointCol)}$row',
          )
          .cellStyle
          .fontColor = finLecColor;

      double finalGradeValue = double.tryParse(ftg) ?? 5.00;
      String finalGradeColor =
          finalGradeValue <= 3.00
              ? ExcelStyleConstants.kPassingGreen
              : ExcelStyleConstants.kFailingRed;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(finalPeriodGradeDataCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(finalPeriodGradeDataCol)}$row',
          )
          .cellStyle
          .fontColor = finalGradeColor;

      // Apply bold and conditional color to all computed final grade values
      // Green if passing (<= 3.00), Red if failing (> 3.00)

      // 1/2 MTG + 1/2 FTG values
      double comp12Value = comp12;
      String comp12Color =
          comp12Value <= 3.00
              ? ExcelStyleConstants.kPassingGreen
              : ExcelStyleConstants.kFailingRed;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(comp12Col)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(comp12Col)}$row')
          .cellStyle
          .fontColor = comp12Color;

      double comp12RemovalValue = comp12Mapped > 3.50 ? 5.00 : comp12Mapped;
      String comp12RemovalColor =
          comp12RemovalValue <= 3.00
              ? ExcelStyleConstants.kPassingGreen
              : ExcelStyleConstants.kFailingRed;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp12RemovalCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp12RemovalCol)}$row',
          )
          .cellStyle
          .fontColor = comp12RemovalColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp12AfterCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp12AfterCol)}$row',
          )
          .cellStyle
          .fontColor = comp12RemovalColor;

      // Description for comp12 - color based on text
      String comp12Desc = gradeCalc.descFromNumeric(comp12);
      String comp12DescColor =
          comp12Desc.toLowerCase() == 'failed'
              ? '#E53935'
              : (comp12Desc.toLowerCase() == 'excellent'
                  ? ExcelStyleConstants.kPassingGreen
                  : '#000000');
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp12DescCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp12DescCol)}$row',
          )
          .cellStyle
          .fontColor = comp12DescColor;

      // 1/3 MTG + 2/3 FTG values
      double comp13Value = comp13;
      String comp13Color =
          comp13Value <= 3.00
              ? ExcelStyleConstants.kPassingGreen
              : ExcelStyleConstants.kFailingRed;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(comp13Col)}$row')
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(comp13Col)}$row')
          .cellStyle
          .fontColor = comp13Color;

      double comp13RemovalValue = comp13Mapped > 3.50 ? 5.00 : comp13Mapped;
      String comp13RemovalColor =
          comp13RemovalValue <= 3.00
              ? ExcelStyleConstants.kPassingGreen
              : ExcelStyleConstants.kFailingRed;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp13RemovalCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp13RemovalCol)}$row',
          )
          .cellStyle
          .fontColor = comp13RemovalColor;

      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp13AfterCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp13AfterCol)}$row',
          )
          .cellStyle
          .fontColor = comp13RemovalColor;

      // Description for comp13 - color based on text
      String comp13Desc = gradeCalc.descFromNumeric(comp13);
      String comp13DescColor =
          comp13Desc.toLowerCase() == 'failed'
              ? '#E53935'
              : (comp13Desc.toLowerCase() == 'excellent'
                  ? ExcelStyleConstants.kPassingGreen
                  : '#000000');
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp13DescCol)}$row',
          )
          .cellStyle
          .bold = true;
      sheet
          .getRangeByName(
            '${ExcelColumnLayout.getColumnLetter(comp13DescCol)}$row',
          )
          .cellStyle
          .fontColor = comp13DescColor;

      // Apply white background to all computed final grade columns (8 columns)
      final computedRange = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(comp12Col)}$row:${ExcelColumnLayout.getColumnLetter(comp13DescCol)}$row',
      );
      computedRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
    }

    // Apply thick black borders to ALL sections as complete rectangles (from row 4 headers to last data row)
    final totalCols = ExcelColumnLayout.totalColumnCount(
      csCount: classStandingItems.length,
      qpCount: quizPrelimItems.length,
      meCount: midtermExamItems.length,
      pitCount: pitItems.length,
      fcsCount: finalClassStandingItems.length,
      fqCount: finalQuizItems.length,
      feCount: finalExamItems.length,
      fpitCount: finalPitItems.length,
    );

    // Calculate section boundaries
    final csGroup = classStandingItems.length + 2;
    final qpGroup = quizPrelimItems.length + 2;
    final meGroup = midtermExamItems.length + 1;
    final pitGroup = pitItems.length + 2;
    final midLectureGroup = 4;
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

    // Section start columns
    final midtermStartCol = 4; // Column D (4)
    final midtermEndCol = 4 + midtermGroup - 1;
    final finalStartCol = 4 + midtermGroup;
    final finalEndCol = 4 + midtermGroup + finalGroup - 1;
    final computedStartCol = 4 + midtermGroup + finalGroup;

    // Apply thick black borders to HEADER rows (rows 4-7) and MAX POINTS row (row 8)
    // Student data rows (9+) will NOT have thick black borders (they have thin borders)
    final headerStartRow = 4;
    final headerEndRow = 7;
    final maxPointsRow = startRow; // Row 8

    // Student info columns (No, ID, Names): headers (rows 4-7) and max points row (row 8)
    final studentInfoHeaderRange = sheet.getRangeByName(
      'A$headerStartRow:C$headerEndRow',
    );
    studentInfoHeaderRange.cellStyle.borders.all.lineStyle = LineStyle.thick;
    studentInfoHeaderRange.cellStyle.borders.all.color =
        ExcelStyleConstants.kBlack;

    final studentInfoMaxPointsRange = sheet.getRangeByName(
      'A$maxPointsRow:C$maxPointsRow',
    );
    studentInfoMaxPointsRange.cellStyle.borders.all.lineStyle = LineStyle.thick;
    studentInfoMaxPointsRange.cellStyle.borders.all.color =
        ExcelStyleConstants.kBlack;

    // Midterm section: headers (rows 4-7) and max points row (row 8)
    final midtermHeaderRange = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(midtermStartCol)}$headerStartRow:${ExcelColumnLayout.getColumnLetter(midtermEndCol)}$headerEndRow',
    );
    midtermHeaderRange.cellStyle.borders.all.lineStyle = LineStyle.thick;
    midtermHeaderRange.cellStyle.borders.all.color = ExcelStyleConstants.kBlack;

    final midtermMaxPointsRange = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(midtermStartCol)}$maxPointsRow:${ExcelColumnLayout.getColumnLetter(midtermEndCol)}$maxPointsRow',
    );
    midtermMaxPointsRange.cellStyle.borders.all.lineStyle = LineStyle.thick;
    midtermMaxPointsRange.cellStyle.borders.all.color =
        ExcelStyleConstants.kBlack;

    // Final section: headers (rows 4-7) and max points row (row 8)
    final finalHeaderRange = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(finalStartCol)}$headerStartRow:${ExcelColumnLayout.getColumnLetter(finalEndCol)}$headerEndRow',
    );
    finalHeaderRange.cellStyle.borders.all.lineStyle = LineStyle.thick;
    finalHeaderRange.cellStyle.borders.all.color = ExcelStyleConstants.kBlack;

    final finalMaxPointsRange = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(finalStartCol)}$maxPointsRow:${ExcelColumnLayout.getColumnLetter(finalEndCol)}$maxPointsRow',
    );
    finalMaxPointsRange.cellStyle.borders.all.lineStyle = LineStyle.thick;
    finalMaxPointsRange.cellStyle.borders.all.color =
        ExcelStyleConstants.kBlack;

    // Computed section: headers (rows 4-7) and max points row (row 8)
    final computedHeaderRange = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(computedStartCol)}$headerStartRow:${ExcelColumnLayout.getColumnLetter(computedStartCol + computedGroup - 1)}$headerEndRow',
    );
    computedHeaderRange.cellStyle.borders.all.lineStyle = LineStyle.thick;
    computedHeaderRange.cellStyle.borders.all.color =
        ExcelStyleConstants.kBlack;

    final computedMaxPointsRange = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(computedStartCol)}$maxPointsRow:${ExcelColumnLayout.getColumnLetter(computedStartCol + computedGroup - 1)}$maxPointsRow',
    );
    computedMaxPointsRange.cellStyle.borders.all.lineStyle = LineStyle.thick;
    computedMaxPointsRange.cellStyle.borders.all.color =
        ExcelStyleConstants.kBlack;

    // Center all content in student data rows, except name column which is left-aligned
    if (students.isNotEmpty) {
      final firstStudentRow = startRow + 1; // First student row (row 9)
      final lastStudentRow = startRow + students.length;

      // Center columns A-B (No, ID)
      final noIdRange = sheet.getRangeByName(
        'A$firstStudentRow:B$lastStudentRow',
      );
      noIdRange.cellStyle.hAlign = HAlignType.center;
      noIdRange.cellStyle.vAlign = VAlignType.center;

      // Center columns D onwards (all grade columns)
      final gradeColumnsRange = sheet.getRangeByName(
        'D$firstStudentRow:${ExcelColumnLayout.getColumnLetter(totalCols)}$lastStudentRow',
      );
      gradeColumnsRange.cellStyle.hAlign = HAlignType.center;
      gradeColumnsRange.cellStyle.vAlign = VAlignType.center;

      // Name column (C) is already set to left-align in the student data writing loop
    }

    // REMOVED: _autoFitColumns(sheet) - it was causing row 7 to auto-expand
    // Column widths will be set manually to ensure category headers are visible

    // Force row 7 height - ensure it stays fixed
    // Row index is 0-based, so row 7 is index 6
    // Note: totalCols is already calculated above

    // Set wrapText = false for non-computed cells - text will be clipped at fixed height
    // But computed columns need wrapText = true, so we'll set them separately
    // First, get the computed start column
    final totalColsBeforeComputed =
        ExcelColumnLayout.totalColumnCount(
          csCount: classStandingItems.length,
          qpCount: quizPrelimItems.length,
          meCount: midtermExamItems.length,
          pitCount: pitItems.length,
          fcsCount: finalClassStandingItems.length,
          fqCount: finalQuizItems.length,
          feCount: finalExamItems.length,
          fpitCount: finalPitItems.length,
        ) -
        8; // 8 is the computed group size

    if (totalColsBeforeComputed > 0) {
      final nonComputedRange = sheet.getRangeByName(
        'A7:${ExcelColumnLayout.getColumnLetter(totalColsBeforeComputed)}7',
      );
      nonComputedRange.cellStyle.wrapText = false;
    }

    // Computed columns (last 8 columns) should have wrapText = true
    final computedRange = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(totalColsBeforeComputed + 1)}7:${ExcelColumnLayout.getColumnLetter(totalCols)}7',
    );
    computedRange.cellStyle.wrapText = true;
    computedRange.cellStyle.hAlign = HAlignType.center;
    computedRange.cellStyle.vAlign = VAlignType.center;

    // Force the row height - taller to accommodate computed column wrapping
    final row7 = sheet.rows[6];
    if (row7 != null) {
      row7.height =
          30; // Increased height to allow computed column headers to wrap and be visible
    }

    // CRITICAL: Set column widths AFTER all content is written
    // This ensures columns exist and widths are properly applied
    ExcelHeaderBuilder.setColumnWidths(sheet, totalCols);

    // CRITICAL: Ensure row 6 category headers are visible even with no items
    // Set minimum widths for category header merged cells
    ExcelHeaderBuilder.ensureRow6CategoryHeaderWidths(
      sheet,
      classStandingItems,
      quizPrelimItems,
      midtermExamItems,
      pitItems,
      finalClassStandingItems,
      finalQuizItems,
      finalExamItems,
      finalPitItems,
    );
  }

  static void writeGradeSheetData(
    Worksheet sheet,
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    GradeCalculator gradeCalc,
  ) {
    int dataStartRow = 10; // Start user data at row 10

    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      int row = dataStartRow + i;
      int col = 1;

      // Basic student info
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setNumber(i + 1); // No.
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(student['idNumber'] ?? ''); // ID Number (swapped position)
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(
            gradeCalc.formatStudentName(student['name'] ?? ''),
          ); // Student Name (formatted) - swapped position

      // Class Standing scores
      for (var item in classStandingItems) {
        String key = gradeCalc.makeItemKey(item);
        String score = gradeCalc.readScore(student, key);
        sheet
            .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
            .setText(score);
      }

      // Calculate and add SRC and CPA
      int src = gradeCalc.calculateGroupTotal(student, classStandingItems);
      double cpa = gradeCalc.calculateGroupPercent(student, classStandingItems);
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(src.toString());
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${cpa.toStringAsFixed(1)}%');

      // Quiz/Prelim scores (only totals, no individual items)
      // Calculate and add SRQ and QA
      int srq = gradeCalc.calculateGroupTotal(student, quizPrelimItems);
      double qa = gradeCalc.calculateGroupPercent(student, quizPrelimItems);
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(srq.toString());
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText('${qa.toStringAsFixed(1)}%');

      // Add borders to row
      final rowRange = sheet.getRangeByName(
        'A$row:${ExcelColumnLayout.getColumnLetter(col - 1)}$row',
      );
      rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
  }

  static void writeStudentListData(
    Worksheet sheet,
    List<Map<String, dynamic>> students,
    GradeCalculator gradeCalc,
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
            gradeCalc.formatStudentName(student['name'] ?? ''),
          ); // Student Name (already in correct position)
      sheet.getRangeByName('D$row').setText(student['email'] ?? '');
      sheet.getRangeByName('E$row').setText(student['enrollmentStatus'] ?? '');

      // Add borders to row
      final rowRange = sheet.getRangeByName('A$row:E$row');
      rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
  }
}
