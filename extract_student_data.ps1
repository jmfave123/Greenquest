$lines = Get-Content -Path "d:\greenquest\lib\shared\services\export_service.dart"
$content = @"
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'excel_style_constants.dart';
import 'excel_column_layout.dart';
import 'excel_header_builder.dart';
import 'grade_calculator.dart';

class ExcelStudentDataWriter {
"@
$content += "
"
$content += @"
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
"@
$content += "
"

$chunk1 = ($lines[386..1235] -join "
") -replace "_gradeCalc\.", "gradeCalc."
$content += $chunk1
$content += "
  }

"

$chunk2 = ($lines[1357..1425] -join "
") -replace "Future<void> _addGradeSheetData\(", "static Future<void> writeGradeSheetData(" -replace "List<Map<String, dynamic>> quizPrelimItems,", "List<Map<String, dynamic>> quizPrelimItems,
    GradeCalculator gradeCalc," -replace "_gradeCalc\.", "gradeCalc."
$content += $chunk2
$content += "
  }

"

$chunk3 = ($lines[1428..1456] -join "
") -replace "void _addStudentListData\(", "static void writeStudentListData(" -replace "List<Map<String, dynamic>> students,", "List<Map<String, dynamic>> students,
    GradeCalculator gradeCalc," -replace "_gradeCalc\.", "gradeCalc."
$content += $chunk3
$content += "
  }
"
$content += "
}
"

$content | Set-Content -Path "d:\greenquest\lib\shared\services\export\excel_student_data_writer.dart"

$newLines = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -ge 386 -and $i -le 1235) {
        if ($i -eq 386) {
            $newLines += "      ExcelStudentDataWriter.writeCompleteClassRecordData("
            $newLines += "        sheet,"
            $newLines += "        startRow,"
            $newLines += "        students,"
            $newLines += "        classStandingItems,"
            $newLines += "        quizPrelimItems,"
            $newLines += "        midtermExamItems,"
            $newLines += "        pitItems,"
            $newLines += "        finalClassStandingItems,"
            $newLines += "        finalQuizItems,"
            $newLines += "        finalExamItems,"
            $newLines += "        finalPitItems,"
            $newLines += "        _gradeCalc,"
            $newLines += "      );"
        }
        continue
    }
    if ($i -ge 1357 -and $i -le 1426) { continue }
    if ($i -ge 1428 -and $i -le 1457) { continue }
    $newLines += $lines[$i]
}

$serviceContent = $newLines -join "
"
$serviceContent = $serviceContent -replace "import 'export/excel_max_points_row_builder.dart';", "import 'export/excel_max_points_row_builder.dart';
import 'export/excel_student_data_writer.dart';"
$serviceContent = $serviceContent -replace "_addStudentListData\(sheet, students\);", "ExcelStudentDataWriter.writeStudentListData(sheet, students, _gradeCalc);"
$serviceContent = $serviceContent -replace "(?s)await _addGradeSheetData\(\s*sheet,\s*students,\s*classStandingItems,\s*quizPrelimItems,\s*\);", "await ExcelStudentDataWriter.writeGradeSheetData(
        sheet,
        students,
        classStandingItems,
        quizPrelimItems,
        _gradeCalc,
      );"

$serviceContent | Set-Content -Path "d:\greenquest\lib\shared\services\export_service.dart"
