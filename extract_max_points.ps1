$lines = Get-Content -Path "d:\greenquest\lib\shared\services\export_service.dart"

$content = @"
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'excel_style_constants.dart';
import 'excel_column_layout.dart';
import 'grade_calculator.dart';

class ExcelMaxPointsRowBuilder {
"@
$content += "
"

$maxPointsText = ($lines[1246..1505] -join "
")
$maxPointsText = $maxPointsText -replace "void _writeMaxPointsRow\(", "static void writeMaxPointsRow("
$maxPointsText = $maxPointsText -replace "int row,", "int row,
    GradeCalculator gradeCalc,"
$maxPointsText = $maxPointsText -replace "_gradeCalc\.", "gradeCalc."

$content += $maxPointsText
$content += "
}
"

$content | Set-Content -Path "d:\greenquest\lib\shared\services\export\excel_max_points_row_builder.dart"

$newLines = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -ge 1246 -and $i -le 1505) { continue }
    $newLines += $lines[$i]
}
$serviceContent = $newLines -join "
"
$serviceContent = $serviceContent -replace "import 'export/excel_header_builder.dart';", "import 'export/excel_header_builder.dart';
import 'export/excel_max_points_row_builder.dart';"
$serviceContent = $serviceContent -replace "(?s)_writeMaxPointsRow\(\s*sheet,\s*startRow,", "ExcelMaxPointsRowBuilder.writeMaxPointsRow(
        sheet,
        startRow,
        _gradeCalc,"

$serviceContent | Set-Content -Path "d:\greenquest\lib\shared\services\export_service.dart"
