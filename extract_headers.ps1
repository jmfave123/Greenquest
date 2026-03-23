$lines = Get-Content -Path "d:\greenquest\lib\shared\services\export_service.dart"

$content = @"
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'excel_style_constants.dart';
import 'excel_column_layout.dart';
import 'grade_calculator.dart';

class ExcelHeaderBuilder {
"@

$content += "
"
$complete = ($lines[1244..2149] -replace "void _setupCompleteHeaders", "static void setupCompleteHeaders" -replace "_gradeCalc\.", "gradeCalc." -replace "Worksheet sheet,", "Worksheet sheet, GradeCalculator gradeCalc,") -join "
"
$content += $complete
$content += "
"

$studentList = ($lines[2515..2556] -replace "void _setupStudentListHeaders", "static void setupStudentListHeaders") -join "
"
$content += $studentList
$content += "
"

$gradeSheet = ($lines[2559..2726] -replace "void _setupGradeSheetHeaders", "static void setupGradeSheetHeaders") -join "
"
$content += $gradeSheet
$content += "
"

$row6Widths = ($lines[2932..3060] -replace "void _ensureRow6CategoryHeaderWidths", "static void ensureRow6CategoryHeaderWidths") -join "
"
$content += $row6Widths
$content += "
"

$colWidths = ($lines[3064..3097] -replace "void _setColumnWidths", "static void setColumnWidths") -join "
"
$content += $colWidths

$content += "
}
"

$content -replace "
", "
" | Set-Content -Path "d:\greenquest\lib\shared\services\export\excel_header_builder.dart"
