import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'excel_style_constants.dart';

/// Handles column indexing, letter generation, and width formatting for the Excel sheet.
class ExcelColumnLayout {
  // Prevent instantiation — all members are static utilities.
  const ExcelColumnLayout._();

  /// Converts a 1-based column number to its Excel column letter (e.g. 1 -> A, 27 -> AA).
  static String getColumnLetter(int columnNumber) {
    String result = '';
    while (columnNumber > 0) {
      columnNumber--;
      result = String.fromCharCode(65 + (columnNumber % 26)) + result;
      columnNumber ~/= 26;
    }
    return result;
  }

  /// Calculates the total number of columns required for the complete class record,
  /// based on the item lists provided.
  static int totalColumnCount({
    required int csCount,
    required int qpCount,
    required int meCount,
    required int pitCount,
    required int fcsCount,
    required int fqCount,
    required int feCount,
    required int fpitCount,
  }) {
    // No, ID, Names
    int count = 3;
    count += csCount + 2; // items + SRC + CPA
    count += qpCount + 2; // items + SRQ + QA
    count += meCount + 1; // items + M
    count += pitCount + 2; // items + PIT total + PIT%
    count += 4; // MGA + Mid Lec + Mid GP + Midterm Grade
    count += fcsCount + 2; // final cs + SRC + CPA
    count += fqCount + 2; // final quiz + SRQ + QA
    count += feCount + 1; // final exam + F
    count += fpitCount + 2; // final pit + total + %
    count += 4; // FGA + Fin Lec + Fin GP + Final Period Grade
    count += 8; // computed 8 cols
    return count;
  }

  /// Applies standard column widths for the three initial columns.
  static void setupBaseColumnWidths(Worksheet sheet) {
    sheet.getRangeByName('A1').columnWidth = ExcelStyleConstants.kNumberColumnWidth;
    sheet.getRangeByName('B1').columnWidth = ExcelStyleConstants.kIdColumnWidth;
    sheet.getRangeByName('C1').columnWidth = ExcelStyleConstants.kNameColumnWidth;
  }

  /// Applies summary column widths to specific column numbers.
  static void setSummaryColumnWidths(Worksheet sheet, List<int> columnNumbers) {
    for (int col in columnNumbers) {
      sheet.getRangeByName('${getColumnLetter(col)}1').columnWidth = ExcelStyleConstants.kSummaryColumnWidth;
    }
  }

  /// Applies computed column widths to specific column numbers.
  static void setComputedColumnWidths(Worksheet sheet, List<int> columnNumbers) {
    for (int col in columnNumbers) {
      sheet.getRangeByName('${getColumnLetter(col)}1').columnWidth = ExcelStyleConstants.kComputedColumnWidth;
    }
  }

  /// Applies the default narrow width to item columns within a range.
  static void setItemColumnWidths(Worksheet sheet, int startCol, int endCol) {
    for (int col = startCol; col < endCol; col++) {
      sheet.getRangeByName('${getColumnLetter(col)}1').columnWidth = ExcelStyleConstants.kDefaultColumnWidth;
    }
  }
}
