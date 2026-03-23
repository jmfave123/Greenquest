$lines = Get-Content -Path "d:\greenquest\lib\shared\services\export_service.dart"
$linesCount = $lines.Count
$newLines = @()
for ($i = 0; $i -lt $linesCount; $i++) {
    if ($i -ge 1244 -and $i -le 2149) { continue }
    if ($i -ge 2515 -and $i -le 2556) { continue }
    if ($i -ge 2559 -and $i -le 2726) { continue }
    if ($i -ge 2932 -and $i -le 3060) { continue }
    if ($i -ge 3064 -and $i -le 3097) { continue }
    $newLines += $lines[$i]
}
$content = $newLines -join "
"
$content = $content -replace "import 'export/excel_column_layout.dart';", "import 'export/excel_column_layout.dart';
import 'export/excel_header_builder.dart';"
$content = $content -replace "_setupCompleteHeaders\(", "ExcelHeaderBuilder.setupCompleteHeaders("
$content = $content -replace "ExcelHeaderBuilder.setupCompleteHeaders\(
        sheet,
        classStandingItems,", "ExcelHeaderBuilder.setupCompleteHeaders(
        sheet,
        _gradeCalc,
        classStandingItems,"
$content = $content -replace "_setupStudentListHeaders\(", "ExcelHeaderBuilder.setupStudentListHeaders("
$content = $content -replace "_setupGradeSheetHeaders\(", "ExcelHeaderBuilder.setupGradeSheetHeaders("
$content = $content -replace "_ensureRow6CategoryHeaderWidths\(", "ExcelHeaderBuilder.ensureRow6CategoryHeaderWidths("
$content = $content -replace "_setColumnWidths\(", "ExcelHeaderBuilder.setColumnWidths("

$content -replace "
", "
" | Set-Content -Path "d:\greenquest\lib\shared\services\export_service.dart"
