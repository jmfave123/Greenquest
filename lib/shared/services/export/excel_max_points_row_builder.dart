import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'excel_style_constants.dart';
import 'excel_column_layout.dart';
import 'grade_calculator.dart';

class ExcelMaxPointsRowBuilder {
  static void writeMaxPointsRow(
    Worksheet sheet,
    int row,
    GradeCalculator gradeCalc,
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
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('No.');
    // ID Number
    int idCol = col;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('ID Number');
    // Names
    int namesCol = col;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('Names');

    int csMax = gradeCalc.maxPoints(classStandingItems);
    int csItemsStartCol = col;
    for (var item in classStandingItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int csItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText(csMax.toString());
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');

    int qpMax = gradeCalc.maxPoints(quizPrelimItems);
    int qpItemsStartCol = col;
    for (var item in quizPrelimItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int qpItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText(qpMax.toString());
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');

    int meItemsStartCol = col;
    for (var item in midtermExamItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int meItemsEndCol = col;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');

    int pitMax = gradeCalc.maxPoints(pitItems);
    int pitItemsStartCol = col;
    for (var item in pitItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int pitItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText(pitMax.toString());
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');

    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');
    int midLecGradePointMaxCol = col;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.000');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.000');
    int midtermGradeMaxCol = col;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.00');

    int fcsMax = gradeCalc.maxPoints(finalClassStandingItems);
    int fcsItemsStartCol = col;
    for (var item in finalClassStandingItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int fcsItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText(fcsMax.toString());
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');

    int fqMax = gradeCalc.maxPoints(finalQuizItems);
    int fqItemsStartCol = col;
    for (var item in finalQuizItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int fqItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText(fqMax.toString());
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');

    int feItemsStartCol = col;
    for (var item in finalExamItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int feItemsEndCol = col;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');

    int fpitMax = gradeCalc.maxPoints(finalPitItems);
    int fpitItemsStartCol = col;
    for (var item in finalPitItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText((item['points'] ?? 0).toString());
    }
    int fpitItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText(fpitMax.toString());
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');

    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('100%');
    int finLecGradePointMaxCol = col;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.000');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.000');
    int finalPeriodGradeMaxCol = col;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.00');

    // Computed section defaults
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('Excellent');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('1.00');
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row').setText('Excellent');

    final rowRange = sheet.getRangeByName(
      'A$row:${ExcelColumnLayout.getColumnLetter(col - 1)}$row',
    );
    rowRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
    rowRange.cellStyle.backColor = ExcelStyleConstants.kWhite; // White background
    rowRange.cellStyle.fontColor = ExcelStyleConstants.kSummaryFontColor; // Foreground text color

    // Style No., ID Number, and Names columns: BOLD, white background, black foreground
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(noCol)}$row').cellStyle.bold =
        true;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(noCol)}$row').cellStyle.backColor =
        ExcelStyleConstants.kWhite;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(noCol)}$row').cellStyle.fontColor =
        ExcelStyleConstants.kBlack;

    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(idCol)}$row').cellStyle.bold =
        true;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(idCol)}$row').cellStyle.backColor =
        ExcelStyleConstants.kWhite;
    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(idCol)}$row').cellStyle.fontColor =
        ExcelStyleConstants.kBlack;

    sheet.getRangeByName('${ExcelColumnLayout.getColumnLetter(namesCol)}$row').cellStyle.bold =
        true;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(namesCol)}$row')
        .cellStyle
        .backColor = ExcelStyleConstants.kWhite;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(namesCol)}$row')
        .cellStyle
        .fontColor = ExcelStyleConstants.kBlack;

    // Make all max points numbers bold (starting from column 4, after No., ID Number, Names)
    final numbersRange = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(4)}$row:${ExcelColumnLayout.getColumnLetter(col - 1)}$row',
    );
    numbersRange.cellStyle.bold = true;

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
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(midLecGradePointMaxCol)}$row')
        .cellStyle
        .backColor = ExcelStyleConstants.kComputedGreenBg;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(finLecGradePointMaxCol)}$row')
        .cellStyle
        .backColor = ExcelStyleConstants.kComputedGreenBg;

    // Apply #FFC000 background to Midterm Grade and Final Period Grade columns
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(midtermGradeMaxCol)}$row')
        .cellStyle
        .backColor = ExcelStyleConstants.kHeaderOrangeBg;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(finalPeriodGradeMaxCol)}$row')
        .cellStyle
        .backColor = ExcelStyleConstants.kHeaderOrangeBg;

    // Center all content in row 8 (max points row)
    final totalColumns = col - 1;
    final row8Range = sheet.getRangeByName(
      'A$row:${ExcelColumnLayout.getColumnLetter(totalColumns)}$row',
    );
    row8Range.cellStyle.hAlign = HAlignType.center;
    row8Range.cellStyle.vAlign = VAlignType.center;
  }
}

