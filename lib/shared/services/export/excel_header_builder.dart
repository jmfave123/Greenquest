import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'excel_style_constants.dart';
import 'excel_column_layout.dart';
import 'grade_calculator.dart';

class ExcelHeaderBuilder {
  static void setupCompleteHeaders(
    Worksheet sheet,
    GradeCalculator gradeCalc,
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
    sheet
        .getRangeByName(
          'A1:${ExcelColumnLayout.getColumnLetter(totalColumns)}1',
        )
        .merge();
    sheet
        .getRangeByName('A1')
        .setText('Department of NATIONAL SERVICE TRAINING PROGRAM');
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A1').cellStyle.backColor = ExcelStyleConstants.kWhite;

    // Row 2: Subject (merged across all columns)
    sheet
        .getRangeByName(
          'A2:${ExcelColumnLayout.getColumnLetter(totalColumns)}2',
        )
        .merge();
    sheet.getRangeByName('A2').setText('Subject: NSTP 101C');
    sheet.getRangeByName('A2').cellStyle.bold = true;
    sheet.getRangeByName('A2').cellStyle.backColor = ExcelStyleConstants.kWhite;

    // Row 4: Top stacked headers for sections
    row = 4;
    int col = 1;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + 3 - 1)}$row',
        )
        .merge();
    // spacer for student info columns
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col)}$row')
        .setText('');
    col += 3;

    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + midtermGroup - 1)}$row',
        )
        .merge();
    final midtermHeaderRow4 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row',
    );
    midtermHeaderRow4.setText('Midterm Grade');
    midtermHeaderRow4.cellStyle.hAlign = HAlignType.center;
    midtermHeaderRow4.cellStyle.bold = true;
    midtermHeaderRow4.cellStyle.backColor = ExcelStyleConstants.kHeaderBlueBg;
    // Borders will be applied to complete section rectangle at the end
    col += midtermGroup;

    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + finalGroup - 1)}$row',
        )
        .merge();
    final finalHeaderRow4 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row',
    );
    finalHeaderRow4.setText('Final Grade');
    finalHeaderRow4.cellStyle.hAlign = HAlignType.center;
    finalHeaderRow4.cellStyle.bold = true;
    finalHeaderRow4.cellStyle.backColor = ExcelStyleConstants.kHeaderBlueBg;
    // Borders will be applied to complete section rectangle at the end
    col += finalGroup;

    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + computedGroup - 1)}$row',
        )
        .merge();
    final computedHeaderRow4 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row',
    );
    computedHeaderRow4.setText('Computed Final Grade');
    computedHeaderRow4.cellStyle.hAlign = HAlignType.center;
    computedHeaderRow4.cellStyle.bold = true;
    computedHeaderRow4.cellStyle.backColor =
        ExcelStyleConstants.kMidtermHeaderGreenBg;
    computedHeaderRow4.cellStyle.fontColor = ExcelStyleConstants.kWhite;
    // Borders will be applied to complete section rectangle at the end

    // Row 5: Lecture 100% over midterm and final groups
    row = 5;
    col = 4;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + midtermGroup - 1)}$row',
        )
        .merge();
    final midtermLectureRow5 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row',
    );
    midtermLectureRow5.setText('Lecture 100%');
    midtermLectureRow5.cellStyle.backColor =
        ExcelStyleConstants.kHeaderOrangeBg;
    midtermLectureRow5.cellStyle.bold = true;
    midtermLectureRow5.cellStyle.hAlign = HAlignType.center;
    // Borders will be applied to complete section rectangle at the end

    col += midtermGroup;
    final finalLectureRow5 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + finalGroup - 1)}$row',
    );
    finalLectureRow5.merge();
    finalLectureRow5.setText('Lecture 100%');
    finalLectureRow5.cellStyle.backColor = ExcelStyleConstants.kHeaderOrangeBg;
    finalLectureRow5.cellStyle.bold = true;
    finalLectureRow5.cellStyle.hAlign = HAlignType.center;
    // Borders will be applied to complete section rectangle at the end

    // Computed group - extend green background from row 4
    col += finalGroup;
    final computedRow5 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + computedGroup - 1)}$row',
    );
    computedRow5.merge();
    // Apply green background to match row 4
    computedRow5.cellStyle.backColor =
        ExcelStyleConstants.kMidtermHeaderGreenBg;
    // Borders will be applied to complete section rectangle at the end

    // Row 6: Category headers for midterm and final groups
    row = 6;
    col = 4; // midterm start
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + csGroup - 1)}$row',
        )
        .merge();
    // Midterm category headers
    final csCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row',
    );
    csCategoryRow6.setText('Class Standing Performance Items (10%)');
    csCategoryRow6.cellStyle.backColor = ExcelStyleConstants.kCategoryYellowBg;
    csCategoryRow6.cellStyle.bold = true;
    csCategoryRow6.cellStyle.hAlign = HAlignType.center;
    // Borders will be applied to complete section rectangle at the end
    col += csGroup;

    final qpCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + qpGroup - 1)}$row',
    );
    qpCategoryRow6.merge();
    qpCategoryRow6.setText('Quiz/Prelim Performance Item (40%)');
    qpCategoryRow6.cellStyle.backColor = ExcelStyleConstants.kCategoryYellowBg;
    qpCategoryRow6.cellStyle.bold = true;
    qpCategoryRow6.cellStyle.hAlign = HAlignType.center;
    col += qpGroup;

    final meCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + meGroup - 1)}$row',
    );
    meCategoryRow6.merge();
    meCategoryRow6.setText('Midterm Exam (10%)');
    meCategoryRow6.cellStyle.backColor = ExcelStyleConstants.kCategoryYellowBg;
    meCategoryRow6.cellStyle.bold = true;
    meCategoryRow6.cellStyle.hAlign = HAlignType.center;
    col += meGroup;

    final pitCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + pitGroup - 1)}$row',
    );
    pitCategoryRow6.merge();
    pitCategoryRow6.setText('Per Inno Task (20%)');
    pitCategoryRow6.cellStyle.backColor = ExcelStyleConstants.kCategoryYellowBg;
    pitCategoryRow6.cellStyle.bold = true;
    pitCategoryRow6.cellStyle.hAlign = HAlignType.center;
    col += pitGroup;

    final midLectureCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + midLectureGroup - 1)}$row',
    );
    midLectureCategoryRow6.merge();
    midLectureCategoryRow6.setText('Lecture');
    midLectureCategoryRow6.cellStyle.backColor =
        ExcelStyleConstants.kCategoryYellowBg;
    midLectureCategoryRow6.cellStyle.bold = true;
    midLectureCategoryRow6.cellStyle.hAlign = HAlignType.center;

    // Final categories
    col = 4 + midtermGroup;
    final fcsCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + fcsGroup - 1)}$row',
    );
    fcsCategoryRow6.merge();
    fcsCategoryRow6.setText('Class Standing Performance Items (10%)');
    fcsCategoryRow6.cellStyle.backColor = ExcelStyleConstants.kCategoryYellowBg;
    fcsCategoryRow6.cellStyle.bold = true;
    fcsCategoryRow6.cellStyle.hAlign = HAlignType.center;
    col += fcsGroup;

    final fqCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + fqGroup - 1)}$row',
    );
    fqCategoryRow6.merge();
    fqCategoryRow6.setText('Quiz/Pre-final\nPerformance Item (40%)');
    fqCategoryRow6.cellStyle.wrapText = true;
    fqCategoryRow6.cellStyle.backColor = ExcelStyleConstants.kCategoryYellowBg;
    fqCategoryRow6.cellStyle.bold = true;
    fqCategoryRow6.cellStyle.hAlign = HAlignType.center;
    col += fqGroup;

    final feCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + feGroup - 1)}$row',
    );
    feCategoryRow6.merge();
    feCategoryRow6.setText('Final Exam (10%)');
    feCategoryRow6.cellStyle.backColor = ExcelStyleConstants.kCategoryYellowBg;
    feCategoryRow6.cellStyle.bold = true;
    feCategoryRow6.cellStyle.hAlign = HAlignType.center;
    col += feGroup;

    final fpitCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + fpitGroup - 1)}$row',
    );
    fpitCategoryRow6.merge();
    fpitCategoryRow6.setText('Per Inno Task (20%)');
    fpitCategoryRow6.cellStyle.backColor =
        ExcelStyleConstants.kCategoryYellowBg;
    fpitCategoryRow6.cellStyle.bold = true;
    fpitCategoryRow6.cellStyle.hAlign = HAlignType.center;
    col += fpitGroup;

    final finalLectureCategoryRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(col)}$row:${ExcelColumnLayout.getColumnLetter(col + finalLectureGroup - 1)}$row',
    );
    finalLectureCategoryRow6.merge();
    finalLectureCategoryRow6.setText('Lecture');
    finalLectureCategoryRow6.cellStyle.backColor =
        ExcelStyleConstants.kCategoryYellowBg;
    finalLectureCategoryRow6.cellStyle.bold = true;
    finalLectureCategoryRow6.cellStyle.hAlign = HAlignType.center;

    // Computed Final Grade section in row 6 - extend green background from row 4
    col += finalLectureGroup;
    final computedColStartRow6 =
        4 + midtermGroup + finalGroup; // Same as row 4 computed start
    final computedRow6 = sheet.getRangeByName(
      '${ExcelColumnLayout.getColumnLetter(computedColStartRow6)}$row:${ExcelColumnLayout.getColumnLetter(computedColStartRow6 + computedGroup - 1)}$row',
    );
    computedRow6.merge();
    // Apply green background to match row 4
    computedRow6.cellStyle.backColor =
        ExcelStyleConstants.kMidtermHeaderGreenBg;
    computedRow6.cellStyle.hAlign = HAlignType.center;
    // Borders will be applied to complete section rectangle at the end

    // Column widths will be set at the end after all content is written

    // Row 7: Detailed column headers
    row = 7;
    col = 1;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('');
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('');
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('');

    // Track column positions for vertical rotation
    int csItemsStartCol = col;
    for (var item in classStandingItems) {
      final title = gradeCalc.truncateHeaderText(item['title'] ?? '');
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      cell.setText(title);
      cell.cellStyle.wrapText =
          false; // No wrapping - text will be clipped at fixed height
    }
    int csItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Total Score (SRC)');
    int cpaMidCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('CPA');

    int qpItemsStartCol = col;
    for (var item in quizPrelimItems) {
      final title = gradeCalc.truncateHeaderText(item['title'] ?? '');
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      cell.setText(title);
      cell.cellStyle.wrapText =
          false; // No wrapping - text will be clipped at fixed height
    }
    int qpItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Total Score (SRQ)');
    int qaMidCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('QA');

    int meItemsStartCol = col;
    for (var item in midtermExamItems) {
      final title = gradeCalc.truncateHeaderText(item['title'] ?? '');
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      cell.setText(title);
      cell.cellStyle.wrapText =
          false; // No wrapping - text will be clipped at fixed height
    }
    int meItemsEndCol = col;
    int mCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('M');

    int pitItemsStartCol = col;
    for (var item in pitItems) {
      final title = gradeCalc.truncateHeaderText(item['title'] ?? '');
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      cell.setText(title);
      cell.cellStyle.wrapText =
          false; // No wrapping - text will be clipped at fixed height
    }
    int pitItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Total Score (PIT)');
    int pitPercentMidCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('PIT%');

    int mgaCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('MGA');
    int midLecGradePointCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Mid Lec Grade Point');
    int midGradePointCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Mid Grade Point');
    int midtermGradeCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Midterm Grade');

    int fcsItemsStartCol = col;
    for (var item in finalClassStandingItems) {
      final title = gradeCalc.truncateHeaderText(item['title'] ?? '');
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      cell.setText(title);
      cell.cellStyle.wrapText =
          false; // No wrapping - text will be clipped at fixed height
    }
    int fcsItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Total Score (SRC)');
    int cpaFinalCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('CPA');

    int fqItemsStartCol = col;
    for (var item in finalQuizItems) {
      final title = gradeCalc.truncateHeaderText(item['title'] ?? '');
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      cell.setText(title);
      cell.cellStyle.wrapText =
          false; // No wrapping - text will be clipped at fixed height
    }
    int fqItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Total Score (SRQ)');
    int qaFinalCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('QA');

    int feItemsStartCol = col;
    for (var item in finalExamItems) {
      final title = gradeCalc.truncateHeaderText(item['title'] ?? '');
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      cell.setText(title);
      cell.cellStyle.wrapText =
          false; // No wrapping - text will be clipped at fixed height
    }
    int feItemsEndCol = col;
    int fCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('F');

    int fpitItemsStartCol = col;
    for (var item in finalPitItems) {
      final title = gradeCalc.truncateHeaderText(item['title'] ?? '');
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(col++)}$row',
      );
      cell.setText(title);
      cell.cellStyle.wrapText =
          false; // No wrapping - text will be clipped at fixed height
    }
    int fpitItemsEndCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Total Score (PIT)');
    int pitPercentFinalCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('PIT%');

    int fgaCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('FGA');
    int finLecGradePointCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Fin Lec Grade Point');
    int finGradePointCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Fin Grade Point');
    int finalPeriodGradeCol = col;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Final Period Grade');

    int computedStartCol = col;
    // Computed Final Grade columns - horizontal text with wrapping (NOT rotated)
    final comp12Col = col++;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(comp12Col)}$row')
        .setText('1/2 MTG + 1/2 FTG');
    final comp12RemovalCol = col++;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(comp12RemovalCol)}$row',
        )
        .setText('1/2 MTG + 1/2 FTG (For Removal)');
    final comp12AfterCol = col++;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(comp12AfterCol)}$row',
        )
        .setText('1/2 MTG + 1/2 FTG (After Removal)');
    final comp12DescCol = col++;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(comp12DescCol)}$row',
        )
        .setText('Description');
    final comp13Col = col++;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(comp13Col)}$row')
        .setText('1/3 MTG + 2/3 FTG');
    final comp13RemovalCol = col++;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(comp13RemovalCol)}$row',
        )
        .setText('1/3 MTG + 2/3 FTG (For Removal)');
    final comp13AfterCol = col++;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(comp13AfterCol)}$row',
        )
        .setText('1/3 MTG + 2/3 FTG (After Removal)');
    final comp13DescCol = col++;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(comp13DescCol)}$row',
        )
        .setText('Description');

    // Set computed columns to horizontal (no rotation) with text wrapping
    for (int i = computedStartCol; i < col; i++) {
      final cell = sheet.getRangeByName(
        '${ExcelColumnLayout.getColumnLetter(i)}$row',
      );
      cell.cellStyle.rotation = 0; // Horizontal text (no rotation)
      cell.cellStyle.wrapText = true; // Enable text wrapping
      cell.cellStyle.hAlign = HAlignType.center; // Center align
      cell.cellStyle.vAlign = VAlignType.center; // Center vertical align
    }

    // Borders for row 7 will be applied as part of the complete section rectangles at the end

    // Set header styling - all normal first
    final headerRange = sheet.getRangeByName(
      'A$row:${ExcelColumnLayout.getColumnLetter(col - 1)}$row',
    );
    headerRange.cellStyle.bold = false; // Set all to normal first
    headerRange.cellStyle.backColor =
        ExcelStyleConstants.kWhite; // White background
    // Note: Individual section borders are set above, so thin borders are only for cells not in sections

    // Set bold for specific columns: Midterm
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaMidCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaMidCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(mCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol)}$row',
        )
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(mgaCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midLecGradePointCol)}$row',
        )
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midGradePointCol)}$row',
        )
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midtermGradeCol)}$row',
        )
        .cellStyle
        .bold = true;
    // Apply #FFC000 background to Midterm Grade header
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midtermGradeCol)}$row',
        )
        .cellStyle
        .backColor = ExcelStyleConstants.kHeaderOrangeBg;

    // Set bold for specific columns: Final
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaFinalCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaFinalCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(fCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol)}$row',
        )
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(fgaCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finLecGradePointCol)}$row',
        )
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finGradePointCol)}$row',
        )
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finalPeriodGradeCol)}$row',
        )
        .cellStyle
        .bold = true;
    // Apply #FFC000 background to Final Period Grade header
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finalPeriodGradeCol)}$row',
        )
        .cellStyle
        .backColor = ExcelStyleConstants.kHeaderOrangeBg;

    // Set bold for all computed final grade columns (8 columns)
    for (int i = computedStartCol; i < col; i++) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(i)}$row')
          .cellStyle
          .bold = true;
    }

    // Make the first three header cells (No., ID Number, Names) appear white
    // to look like normal cells after removing labels.
    final infoHeaderRange = sheet.getRangeByName('A$row:C$row');
    infoHeaderRange.cellStyle.backColor = ExcelStyleConstants.kWhite;

    // Apply vertical text rotation (90 degrees) to item columns and related columns
    // This makes them read from bottom to top, like in the image

    // Midterm item columns
    if (csItemsEndCol > csItemsStartCol) {
      for (int i = csItemsStartCol; i < csItemsEndCol; i++) {
        final cell = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(i)}$row',
        );
        cell.cellStyle.rotation =
            90; // 90 degrees rotation (vertical, reading bottom to top)
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.bottom; // Bottom align for row 7
      }
    }
    // CPA, Total Score columns for midterm
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(cpaMidCol - 1)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(cpaMidCol - 1)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(cpaMidCol - 1)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaMidCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaMidCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaMidCol)}$row')
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    if (qpItemsEndCol > qpItemsStartCol) {
      for (int i = qpItemsStartCol; i < qpItemsEndCol; i++) {
        final cell = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(i)}$row',
        );
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.bottom; // Bottom align for row 7
      }
    }
    // QA, Total Score columns for midterm
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(qaMidCol - 1)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(qaMidCol - 1)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(qaMidCol - 1)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaMidCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaMidCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaMidCol)}$row')
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    if (meItemsEndCol > meItemsStartCol) {
      for (int i = meItemsStartCol; i < meItemsEndCol; i++) {
        final cell = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(i)}$row',
        );
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.bottom; // Bottom align for row 7
      }
    }
    // M column
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(mCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(mCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(mCol)}$row')
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    if (pitItemsEndCol > pitItemsStartCol) {
      for (int i = pitItemsStartCol; i < pitItemsEndCol; i++) {
        final cell = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(i)}$row',
        );
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.bottom; // Bottom align for row 7
      }
    }
    // PIT%, Total Score columns for midterm
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol - 1)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol - 1)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol - 1)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentMidCol)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    // MGA column
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(mgaCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(mgaCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(mgaCol)}$row')
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    // Final item columns
    if (fcsItemsEndCol > fcsItemsStartCol) {
      for (int i = fcsItemsStartCol; i < fcsItemsEndCol; i++) {
        final cell = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(i)}$row',
        );
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.bottom; // Bottom align for row 7
      }
    }
    // CPA, Total Score columns for final
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(cpaFinalCol - 1)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(cpaFinalCol - 1)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(cpaFinalCol - 1)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaFinalCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaFinalCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(cpaFinalCol)}$row')
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    if (fqItemsEndCol > fqItemsStartCol) {
      for (int i = fqItemsStartCol; i < fqItemsEndCol; i++) {
        final cell = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(i)}$row',
        );
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.bottom; // Bottom align for row 7
      }
    }
    // QA, Total Score columns for final
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(qaFinalCol - 1)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(qaFinalCol - 1)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(qaFinalCol - 1)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaFinalCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaFinalCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(qaFinalCol)}$row')
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    if (feItemsEndCol > feItemsStartCol) {
      for (int i = feItemsStartCol; i < feItemsEndCol; i++) {
        final cell = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(i)}$row',
        );
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.bottom; // Bottom align for row 7
      }
    }
    // F column
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(fCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(fCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(fCol)}$row')
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    if (fpitItemsEndCol > fpitItemsStartCol) {
      for (int i = fpitItemsStartCol; i < fpitItemsEndCol; i++) {
        final cell = sheet.getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(i)}$row',
        );
        cell.cellStyle.rotation = 90;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.bottom; // Bottom align for row 7
      }
    }
    // PIT%, Total Score columns for final
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol - 1)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol - 1)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol - 1)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(pitPercentFinalCol)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    // FGA column
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(fgaCol)}$row')
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(fgaCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(fgaCol)}$row')
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    // Mid Lec Grade Point, Mid Grade Point, Midterm Grade columns
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midLecGradePointCol)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midLecGradePointCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midLecGradePointCol)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midGradePointCol)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midGradePointCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midGradePointCol)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midtermGradeCol)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midtermGradeCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(midtermGradeCol)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    // Fin Lec Grade Point, Fin Grade Point, Final Period Grade columns
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finLecGradePointCol)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finLecGradePointCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finLecGradePointCol)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finGradePointCol)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finGradePointCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finGradePointCol)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finalPeriodGradeCol)}$row',
        )
        .cellStyle
        .rotation = 90;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finalPeriodGradeCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(finalPeriodGradeCol)}$row',
        )
        .cellStyle
        .vAlign = VAlignType.bottom; // Bottom align for row 7

    // Align row 7 content - horizontal center, vertical BOTTOM (so text stays at bottom if row expands)
    // BUT: Computed Final Grade columns should have center vertical alignment and wrapping enabled
    // So we'll set alignment for non-computed columns first, then computed columns separately
    if (computedStartCol > 1) {
      final nonComputedRange = sheet.getRangeByName(
        'A$row:${ExcelColumnLayout.getColumnLetter(computedStartCol - 1)}$row',
      );
      nonComputedRange.cellStyle.hAlign = HAlignType.center;
      nonComputedRange.cellStyle.vAlign = VAlignType.bottom;
      nonComputedRange.cellStyle.wrapText = false;
    }

    // Computed columns already have wrapText = true and center alignment set above
    // For computed columns to wrap properly, we need a taller row height
    // Set row 7 height - taller to accommodate wrapped text in computed columns
    // Row index is 0-based, so row 7 is index 6
    final row7 = sheet.rows[6];
    if (row7 != null) {
      // Computed columns have wrapping enabled, so increase height to show wrapped text
      // Other columns will still respect this height (rotated text will be clipped at this height)
      row7.height =
          30; // Increased height to allow computed column headers to wrap and be visible
    }
  }

  static void setupStudentListHeaders(
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
    sheet.getRangeByName('A$row').cellStyle.backColor =
        ExcelStyleConstants.kTitleBlueBg;
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
    headerRange.cellStyle.backColor = ExcelStyleConstants.kWhite;
    headerRange.cellStyle.fontColor = ExcelStyleConstants.kBlack;
    headerRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
  }

  static void setupGradeSheetHeaders(
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
    sheet
        .getRangeByName(
          'A$row:${ExcelColumnLayout.getColumnLetter(totalColumns)}$row',
        )
        .merge();
    sheet.getRangeByName('A$row').setText('MIDTERM GRADE');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    sheet.getRangeByName('A$row').cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A$row').cellStyle.backColor =
        ExcelStyleConstants.kHeaderBlueBg; // Light blue
    row++;

    // Row 2: LECTURE 100% (merged across all columns)
    sheet
        .getRangeByName(
          'A$row:${ExcelColumnLayout.getColumnLetter(totalColumns)}$row',
        )
        .merge();
    sheet.getRangeByName('A$row').setText('LECTURE 100%');
    sheet.getRangeByName('A$row').cellStyle.bold = true;
    sheet.getRangeByName('A$row').cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A$row').cellStyle.backColor =
        ExcelStyleConstants.kHeaderOrangeBg; // Orange
    row++;

    // Row 3: Performance Categories
    int classStandingCols = classStandingItems.length + 2; // items + SRC + CPA
    int quizPrelimCols = 2; // Only SRQ + QA (no individual items)
    int startCol = 4; // After No, ID Number, Names

    // Class Standing Performance Items
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(startCol)}$row:${ExcelColumnLayout.getColumnLetter(startCol + classStandingCols - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(startCol)}$row')
        .setText('CLASS STANDING PERFORMANCE ITEMS (10%)');
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(startCol)}$row')
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(startCol)}$row')
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(startCol)}$row')
        .cellStyle
        .backColor = ExcelStyleConstants.kCategoryYellowBg; // Yellow

    // Quiz/Prelim Performance Item
    int quizStartCol = startCol + classStandingCols;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(quizStartCol)}$row:${ExcelColumnLayout.getColumnLetter(quizStartCol + quizPrelimCols - 1)}$row',
        )
        .merge();
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(quizStartCol)}$row',
        )
        .setText('PRELIM PERFORMANCE ITEM');
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(quizStartCol)}$row',
        )
        .cellStyle
        .bold = true;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(quizStartCol)}$row',
        )
        .cellStyle
        .hAlign = HAlignType.center;
    sheet
        .getRangeByName(
          '${ExcelColumnLayout.getColumnLetter(quizStartCol)}$row',
        )
        .cellStyle
        .backColor = ExcelStyleConstants.kCategoryYellowBg; // Yellow
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
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('No.');
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('ID Number'); // Swapped position
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Names'); // Swapped position

    // Class Standing Items
    for (var item in classStandingItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(item['title'] ?? 'Unknown');
    }
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Total Score (SRC)');
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('CPA');

    // Quiz/Prelim Items (only totals, no individual items)
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('Total Score (SRQ)');
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('QA');

    // Style headers
    final headerRange = sheet.getRangeByName(
      'A$row:${ExcelColumnLayout.getColumnLetter(totalColumns)}$row',
    );
    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.backColor = ExcelStyleConstants.kColumnHeaderBg;
    headerRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
    row++;

    // Row 11: Max Points
    col = 4; // Start after No, ID Number, Names
    for (var item in classStandingItems) {
      sheet
          .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
          .setText(item['points']?.toString() ?? '');
    }
    // Calculate actual SRC total from class standing items
    double srcTotal = 0;
    for (var item in classStandingItems) {
      srcTotal += (item['points'] ?? 0).toDouble();
    }
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText(srcTotal.toString()); // SRC total
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('100%'); // CPA

    // Quiz/Prelim max points (only totals)
    // Calculate actual SRQ total from quiz/prelim items
    double srqTotal = 0;
    for (var item in quizPrelimItems) {
      srqTotal += (item['points'] ?? 0).toDouble();
    }
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText(srqTotal.toString()); // SRQ total
    sheet
        .getRangeByName('${ExcelColumnLayout.getColumnLetter(col++)}$row')
        .setText('100%'); // QA
  }

  static void ensureRow6CategoryHeaderWidths(
    Worksheet sheet,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    List<Map<String, dynamic>> midtermExamItems,
    List<Map<String, dynamic>> pitItems,
    List<Map<String, dynamic>> finalClassStandingItems,
    List<Map<String, dynamic>> finalQuizItems,
    List<Map<String, dynamic>> finalExamItems,
    List<Map<String, dynamic>> finalPitItems,
  ) {
    try {
      // Calculate group sizes (same logic as in _setupCompleteHeaders)
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

      // Minimum width needed for category names (in column width units)
      // Use different minimum widths for different categories based on name length
      const defaultColumnWidth = 12;
      const maxColumnWidth =
          18; // Maximum width per column to prevent excessive widening

      // Helper function to set column widths for a group
      void setGroupWidths(
        int startCol,
        int groupSize,
        String categoryName,
        int minTotalWidth,
      ) {
        final currentTotalWidth = groupSize * defaultColumnWidth;
        if (currentTotalWidth < minTotalWidth) {
          // Calculate width per column, but cap it at maxColumnWidth
          final widthPerColumn = ((minTotalWidth / groupSize).ceil()).clamp(
            defaultColumnWidth,
            maxColumnWidth,
          );
          for (int i = 0; i < groupSize; i++) {
            try {
              final range = sheet.getRangeByIndex(1, startCol + i);
              range.columnWidth = widthPerColumn.toDouble();
            } catch (e) {
              // Skip if column doesn't exist
            }
          }
        }
      }

      // Midterm categories starting at column 4
      int col = 4;

      // Class Standing Performance Items - needs more width for "Class Standing Performance Items (10%)"
      // This is the longest category name, so it needs at least 40-45 width units
      setGroupWidths(col, csGroup, 'Class Standing', 42);
      col += csGroup;

      // Quiz/Prelim Performance Item - "Quiz/Prelim Performance Item (40%)" is also long
      setGroupWidths(col, qpGroup, 'Quiz/Prelim', 35);
      col += qpGroup;

      // Midterm Exam - "Midterm Exam (10%)" is shorter
      setGroupWidths(col, meGroup, 'Midterm Exam', 25);
      col += meGroup;

      // Per Inno Task - "Per Inno Task (20%)" is shorter
      setGroupWidths(col, pitGroup, 'Per Inno Task', 25);
      col += pitGroup;

      // Lecture (midterm) - usually fine with 4 columns
      col += midLectureGroup;

      // Final categories starting at column 4 + midtermGroup
      col = 4 + midtermGroup;

      // Final Class Standing Performance Items - needs more width for "Class Standing Performance Items (10%)"
      // Same as midterm, needs at least 40-45 width units
      setGroupWidths(col, fcsGroup, 'Final Class Standing', 42);
      col += fcsGroup;

      // Quiz/Pre-final Performance Item - "Quiz/Pre-final\nPerformance Item (40%)" is long (with line break)
      setGroupWidths(col, fqGroup, 'Quiz/Pre-final', 35);
      col += fqGroup;

      // Final Exam - "Final Exam (10%)" is shorter
      setGroupWidths(col, feGroup, 'Final Exam', 25);
      col += feGroup;

      // Final Per Inno Task - "Per Inno Task (20%)" is shorter
      setGroupWidths(col, fpitGroup, 'Final Per Inno Task', 25);

      // Computed Final Grade section (8 columns with long headers)
      // Headers like "1/2 MTG + 1/2 FTG (For Removal)" and "1/3 MTG + 2/3 FTG (After Removal)"
      final computedGroup = 8;
      col =
          4 +
          midtermGroup +
          finalGroup; // Computed section starts after final group

      // Computed headers are long, so ensure adequate width
      // Longest header: "1/3 MTG + 2/3 FTG (After Removal)" ~38 chars
      const computedMinWidth = 35; // Minimum total width for computed section
      if (computedGroup * defaultColumnWidth < computedMinWidth) {
        final widthPerColumn = ((computedMinWidth / computedGroup).ceil())
            .clamp(defaultColumnWidth, maxColumnWidth);
        for (int i = 0; i < computedGroup; i++) {
          try {
            final range = sheet.getRangeByIndex(1, col + i);
            range.columnWidth = widthPerColumn.toDouble();
          } catch (e) {
            // Skip if column doesn't exist
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  static void setColumnWidths(Worksheet sheet, int totalColumns) {
    try {
      // Column A (No.) - narrow since it's just numbers
      if (totalColumns >= 1) {
        final rangeA = sheet.getRangeByIndex(1, 1); // Row 1, Column 1 (A)
        rangeA.columnWidth = 8;
      }

      // Column B (ID Number) - wider to fit "ID Number" header and long ID numbers
      if (totalColumns >= 2) {
        final rangeB = sheet.getRangeByIndex(1, 2); // Row 1, Column 2 (B)
        rangeB.columnWidth =
            15; // Wider to accommodate "ID Number" header and ID numbers
      }

      // Column C (Names) - wider width to accommodate varying name lengths
      // Use a width that can handle most names, including long ones
      if (totalColumns >= 3) {
        final rangeC = sheet.getRangeByIndex(1, 3); // Row 1, Column 3 (C)
        rangeC.columnWidth =
            22; // Wider width to accommodate long names like "Ruiz, JM" and longer formats
      }

      // Set minimum widths for all columns starting from column D (col 4) onwards
      // This ensures category headers in merged cells are fully visible
      // Width of 12 per column means merged cells spanning 8 columns = 96 width units
      for (int c = 4; c <= totalColumns; c++) {
        final range = sheet.getRangeByIndex(1, c); // Row 1, Column c (1-based)
        range.columnWidth = 12; // Enough width for category headers when merged
      }
    } catch (e) {
      // Silently handle errors - columns will use default width if setting fails
    }
  }
}
