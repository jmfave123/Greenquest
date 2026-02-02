import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'helpers/column_name_helpers.dart';
import 'calculators/grade_calculator.dart';

class ClassRecordTable extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> classStandingItems;
  final List<Map<String, dynamic>> quizPrelimItems;
  final List<Map<String, dynamic>> midtermExamItems;
  final List<Map<String, dynamic>> pitItems;
  final List<Map<String, dynamic>> finalClassStandingItems;
  final List<Map<String, dynamic>> finalQuizItems;
  final List<Map<String, dynamic>> finalExamItems;
  final List<Map<String, dynamic>> finalPitItems;
  final Function(Map<String, dynamic> student, String itemKey, String value)?
  onCellValueChanged;

  const ClassRecordTable({
    super.key,
    required this.students,
    required this.classStandingItems,
    required this.quizPrelimItems,
    required this.midtermExamItems,
    required this.pitItems,
    required this.finalClassStandingItems,
    required this.finalQuizItems,
    required this.finalExamItems,
    required this.finalPitItems,
    this.onCellValueChanged,
  });

  @override
  State<ClassRecordTable> createState() => _ClassRecordTableState();
}

class _ClassRecordTableState extends State<ClassRecordTable> {
  late ClassRecordDataSource _dataSource;
  late DataGridController _dataGridController;

  @override
  void initState() {
    super.initState();
    _dataGridController = DataGridController();
    _dataSource = ClassRecordDataSource(
      students: widget.students,
      classStandingItems: widget.classStandingItems,
      quizPrelimItems: widget.quizPrelimItems,
      midtermExamItems: widget.midtermExamItems,
      pitItems: widget.pitItems,
      finalClassStandingItems: widget.finalClassStandingItems,
      finalQuizItems: widget.finalQuizItems,
      finalExamItems: widget.finalExamItems,
      finalPitItems: widget.finalPitItems,
      onCellValueChanged: widget.onCellValueChanged,
    );
  }

  @override
  void didUpdateWidget(ClassRecordTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _dataSource.updateData(
      widget.students,
      widget.classStandingItems,
      widget.quizPrelimItems,
      widget.midtermExamItems,
      widget.pitItems,
      widget.finalClassStandingItems,
      widget.finalQuizItems,
      widget.finalExamItems,
      widget.finalPitItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SfDataGrid(
        controller: _dataGridController,
        source: _dataSource,
        frozenColumnsCount: 3, // Keep No., ID, Name always visible
        allowSorting: false,
        allowMultiColumnSorting: false,
        allowColumnsResizing: true,
        columnResizeMode: ColumnResizeMode.onResize,
        gridLinesVisibility: GridLinesVisibility.both,
        headerGridLinesVisibility: GridLinesVisibility.both,
        headerRowHeight: 60,
        rowHeight: 32,
        columnWidthMode: ColumnWidthMode.none,
        onCellTap: (DataGridCellTapDetails details) {
          // Handle cell tap for editing
          if (details.rowColumnIndex.rowIndex > 2) {
            // Skip header rows
            _handleCellTap(details);
          }
        },
        columns: _buildColumns(),
        stackedHeaderRows: _buildStackedHeaderRows(),
      ),
    );
  }

  List<GridColumn> _buildColumns() {
    List<GridColumn> columns = [];

    // Student info columns (frozen)
    columns.addAll([
      GridColumn(
        columnName: 'no',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: const SizedBox.shrink(),
        ),
        width: 60,
      ),
      GridColumn(
        columnName: 'idNumber',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: const SizedBox.shrink(),
        ),
        width: 120,
      ),
      GridColumn(
        columnName: 'name',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: const SizedBox.shrink(),
        ),
        width: 200,
      ),
    ]);

    // Class Standing columns
    for (var item in widget.classStandingItems) {
      columns.add(
        GridColumn(
          columnName: 'cs_${item['id']}',
          label: Container(
            padding: const EdgeInsets.all(6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          width: 100,
        ),
      );
    }

    // Class Standing Total Score and CPA
    columns.addAll([
      GridColumn(
        columnName: 'cs_total',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Total Score (SRC)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'cs_percentage',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'CPA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 80,
      ),
    ]);

    // Quiz/Prelim columns
    for (var item in widget.quizPrelimItems) {
      columns.add(
        GridColumn(
          columnName: 'qp_${item['id']}',
          label: Container(
            padding: const EdgeInsets.all(6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          width: 100,
        ),
      );
    }

    // Quiz/Prelim Total Score and QA
    columns.addAll([
      GridColumn(
        columnName: 'qp_total',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Total Score (SRQ)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'qp_percentage',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'QA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 80,
      ),
    ]);

    // Midterm Exam columns
    for (var item in widget.midtermExamItems) {
      columns.add(
        GridColumn(
          columnName: 'me_${item['id']}',
          label: Container(
            padding: const EdgeInsets.all(6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E1),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          width: 100,
        ),
      );
    }

    // M column (Midterm percentage)
    columns.add(
      GridColumn(
        columnName: 'me_percentage',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE4E1),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'M',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 60,
      ),
    );

    // PIT columns
    for (var item in widget.pitItems) {
      columns.add(
        GridColumn(
          columnName: 'pit_${item['id']}',
          label: Container(
            padding: const EdgeInsets.all(6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8DC),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          width: 100,
        ),
      );
    }

    // PIT Total Score and PIT%
    columns.addAll([
      GridColumn(
        columnName: 'pit_total',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Total Score (PIT)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'pit_percentage',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'PIT%',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 80,
      ),
    ]);

    // Lecture columns
    columns.addAll([
      GridColumn(
        columnName: 'mga',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'MGA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 80,
      ),
      GridColumn(
        columnName: 'mid_lec_grade_point',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Mid Lec Grade Point',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'mid_grade_point',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Mid Grade Point',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
      GridColumn(
        columnName: 'midterm_grade',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Midterm Grade',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
    ]);

    // Final Grade columns - Final Class Standing
    for (var item in widget.finalClassStandingItems) {
      columns.add(
        GridColumn(
          columnName: 'fcs_${item['id']}',
          label: Container(
            padding: const EdgeInsets.all(6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          width: 100,
        ),
      );
    }

    // Final Class Standing Total and CPA
    columns.addAll([
      GridColumn(
        columnName: 'fcs_total',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Total Score (SRC)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'fcs_percentage',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'CPA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 80,
      ),
    ]);

    // Final Quiz columns
    for (var item in widget.finalQuizItems) {
      columns.add(
        GridColumn(
          columnName: 'fq_${item['id']}',
          label: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          width: 100,
        ),
      );
    }

    // Final Quiz Total and QA
    columns.addAll([
      GridColumn(
        columnName: 'fq_total',
        label: Container(
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Total Score (SRQ)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'fq_percentage',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'QA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 80,
      ),
    ]);

    // Final Exam columns
    for (var item in widget.finalExamItems) {
      columns.add(
        GridColumn(
          columnName: 'fe_${item['id']}',
          label: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E1),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          width: 100,
        ),
      );
    }

    // F column (Final percentage)
    columns.add(
      GridColumn(
        columnName: 'fe_percentage',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE4E1),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'F',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 60,
      ),
    );

    // Final PIT columns
    for (var item in widget.finalPitItems) {
      columns.add(
        GridColumn(
          columnName: 'fpit_${item['id']}',
          label: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8DC),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          width: 100,
        ),
      );
    }

    // Final PIT Total and PIT%
    columns.addAll([
      GridColumn(
        columnName: 'fpit_total',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Total Score (PIT)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'fpit_percentage',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'PIT%',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        width: 80,
      ),
    ]);

    // Final Lecture columns
    columns.addAll([
      GridColumn(
        columnName: 'fga',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'FGA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 80,
      ),
      GridColumn(
        columnName: 'final_lec_grade_point',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Fin Lec Grade Poi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'final_grade_point',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Fin Grade Point',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
      GridColumn(
        columnName: 'final_grade',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Final Period Grade',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
    ]);

    // Computed Final Grade columns
    columns.addAll([
      // 1/2 MTG + 1/2 FTG aligned with Final Period Grade but under Computed
      GridColumn(
        columnName: 'comp_half_mtg_ftg',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            '1/2 MTG + 1/2 FTG',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 110,
      ),
      GridColumn(
        columnName: 'comp_12_mtg_ftg_removal',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            '1/2 MTG + 1/2 FTG\n(For Removal)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
      GridColumn(
        columnName: 'comp_12_mtg_ftg_after',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            '1/2 MTG + 1/2 FTG\n(After Removal)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
      GridColumn(
        columnName: 'comp_12_desc',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 120,
      ),
      GridColumn(
        columnName: 'comp_13_mtg_ftg',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            '1/3 MTG + 2/3 FTG',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
      GridColumn(
        columnName: 'comp_13_mtg_ftg_removal',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            '1/3 MTG + 2/3 FTG\n(For Removal)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
      GridColumn(
        columnName: 'comp_13_mtg_ftg_after',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            '1/3 MTG + 2/3 FTG\n(After Removal)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 100,
      ),
      GridColumn(
        columnName: 'comp_13_desc',
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        width: 120,
      ),
    ]);

    return columns;
  }

  List<StackedHeaderRow> _buildStackedHeaderRows() {
    return [
      // Top level header row with four sections
      StackedHeaderRow(
        cells: [
          StackedHeaderCell(
            columnNames: _getStudentInfoColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Department of NATIONAL SERVICE TRAINING PROGRAM',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Subject:  NSTP 101C',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          StackedHeaderCell(
            columnNames: _getGradedItemsColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Midterm Grade',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          StackedHeaderCell(
            columnNames: _getFinalGradedItemsColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Final Grade',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          StackedHeaderCell(
            columnNames: _getComputedFinalGradeColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Computed Final Grade',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      // Second level header - "Lecture 100%" spans midterm graded items
      StackedHeaderRow(
        cells: [
          StackedHeaderCell(
            columnNames: _getGradedItemsColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Lecture 100%',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          StackedHeaderCell(
            columnNames: _getFinalGradedItemsColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Lecture 100%',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          // Blank spacer above computed columns to align with Final headers
          StackedHeaderCell(
            columnNames: _getComputedFinalGradeColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      // Third level headers - Category headers for both Midterm and Final
      StackedHeaderRow(
        cells: [
          // Class Standing Performance Items (10%)
          StackedHeaderCell(
            columnNames: _getClassStandingColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Class Standing Performance Items (10%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Quiz/Prelim Performance Item (40%)
          StackedHeaderCell(
            columnNames: _getQuizPrelimColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Quiz/Prelim Performance Item (40%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Midterm Exam (30%)
          StackedHeaderCell(
            columnNames: _getMidtermExamColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Midterm Exam (30%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Per Inno Task (20%)
          StackedHeaderCell(
            columnNames: _getPitColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Per Inno Task (20%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Lecture
          StackedHeaderCell(
            columnNames: _getLectureColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Lecture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Final Class Standing Performance Items (10%)
          StackedHeaderCell(
            columnNames: _getFinalClassStandingColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Class Standing Performance Items (10%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Final Quiz/Prefinal Performance Item (40%)
          StackedHeaderCell(
            columnNames: _getFinalQuizColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Quiz/Pre-final\nPerformance Item (40%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Final Exam (30%)
          StackedHeaderCell(
            columnNames: _getFinalExamColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Final Exam (30%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Final Per Inno Task (20%)
          StackedHeaderCell(
            columnNames: _getFinalPitColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Per Inno Task (20%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Final Lecture
          StackedHeaderCell(
            columnNames: _getFinalLectureColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Lecture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Second blank spacer above computed columns to push computed headers down
          StackedHeaderCell(
            columnNames: _getComputedFinalGradeColumnNames(),
            child: Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ];
  }

  List<String> _getClassStandingColumnNames() {
    return ColumnNameHelpers.getClassStandingColumnNames(
      widget.classStandingItems,
    );
  }

  List<String> _getQuizPrelimColumnNames() {
    return ColumnNameHelpers.getQuizPrelimColumnNames(widget.quizPrelimItems);
  }

  List<String> _getMidtermExamColumnNames() {
    return ColumnNameHelpers.getMidtermExamColumnNames(widget.midtermExamItems);
  }

  List<String> _getPitColumnNames() {
    return ColumnNameHelpers.getPitColumnNames(widget.pitItems);
  }

  List<String> _getLectureColumnNames() {
    return ColumnNameHelpers.getLectureColumnNames();
  }

  List<String> _getStudentInfoColumnNames() {
    return ColumnNameHelpers.getStudentInfoColumnNames();
  }

  List<String> _getGradedItemsColumnNames() {
    return ColumnNameHelpers.getGradedItemsColumnNames(
      widget.classStandingItems,
      widget.quizPrelimItems,
      widget.midtermExamItems,
      widget.pitItems,
    );
  }

  List<String> _getFinalGradedItemsColumnNames() {
    return ColumnNameHelpers.getFinalGradedItemsColumnNames(
      widget.finalClassStandingItems,
      widget.finalQuizItems,
      widget.finalExamItems,
      widget.finalPitItems,
    );
  }

  List<String> _getFinalClassStandingColumnNames() {
    return ColumnNameHelpers.getFinalClassStandingColumnNames(
      widget.finalClassStandingItems,
    );
  }

  List<String> _getFinalQuizColumnNames() {
    return ColumnNameHelpers.getFinalQuizColumnNames(widget.finalQuizItems);
  }

  List<String> _getFinalExamColumnNames() {
    return ColumnNameHelpers.getFinalExamColumnNames(widget.finalExamItems);
  }

  List<String> _getFinalPitColumnNames() {
    return ColumnNameHelpers.getFinalPitColumnNames(widget.finalPitItems);
  }

  List<String> _getFinalLectureColumnNames() {
    return ColumnNameHelpers.getFinalLectureColumnNames();
  }

  List<String> _getComputedFinalGradeColumnNames() {
    return ColumnNameHelpers.getComputedFinalGradeColumnNames();
  }

  void _handleCellTap(DataGridCellTapDetails details) {
    // Handle cell editing logic here
    // This is where you would implement inline editing
  }
}

class ClassRecordDataSource extends DataGridSource {
  List<Map<String, dynamic>> students;
  List<Map<String, dynamic>> classStandingItems;
  List<Map<String, dynamic>> quizPrelimItems;
  List<Map<String, dynamic>> midtermExamItems;
  List<Map<String, dynamic>> pitItems;
  List<Map<String, dynamic>> finalClassStandingItems;
  List<Map<String, dynamic>> finalQuizItems;
  List<Map<String, dynamic>> finalExamItems;
  List<Map<String, dynamic>> finalPitItems;
  Function(Map<String, dynamic> student, String itemKey, String value)?
  onCellValueChanged;

  late GradeCalculator _calculator;

  /// Format name from "First Middle Last" to "Last, First M." format
  /// Handles: "First Last" -> "Last, First"
  ///          "First Middle Last" -> "Last, First M."
  String _formatStudentName(String name) {
    if (name.isEmpty) return '';

    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return name; // Return as-is if only one part

    // Get the last part (last name)
    final lastName = parts.last;

    // Get first name and middle initial
    if (parts.length == 2) {
      // "First Last" -> "Last, First"
      return '$lastName, ${parts[0]}';
    } else if (parts.length >= 3) {
      // "First Middle Last" -> "Last, First M."
      final firstName = parts[0];
      final middleInitial = parts[1][0].toUpperCase();
      return '$lastName, $firstName $middleInitial.';
    }

    return name;
  }

  ClassRecordDataSource({
    required this.students,
    required this.classStandingItems,
    required this.quizPrelimItems,
    required this.midtermExamItems,
    required this.pitItems,
    required this.finalClassStandingItems,
    required this.finalQuizItems,
    required this.finalExamItems,
    required this.finalPitItems,
    this.onCellValueChanged,
  }) {
    _calculator = GradeCalculator(
      classStandingItems: classStandingItems,
      quizPrelimItems: quizPrelimItems,
      midtermExamItems: midtermExamItems,
      pitItems: pitItems,
      finalClassStandingItems: finalClassStandingItems,
      finalQuizItems: finalQuizItems,
      finalExamItems: finalExamItems,
      finalPitItems: finalPitItems,
    );
  }

  void updateData(
    List<Map<String, dynamic>> newStudents,
    List<Map<String, dynamic>> newClassStandingItems,
    List<Map<String, dynamic>> newQuizPrelimItems,
    List<Map<String, dynamic>> newMidtermExamItems,
    List<Map<String, dynamic>> newPitItems,
    List<Map<String, dynamic>> newFinalClassStandingItems,
    List<Map<String, dynamic>> newFinalQuizItems,
    List<Map<String, dynamic>> newFinalExamItems,
    List<Map<String, dynamic>> newFinalPitItems,
  ) {
    students = newStudents;
    classStandingItems = newClassStandingItems;
    quizPrelimItems = newQuizPrelimItems;
    midtermExamItems = newMidtermExamItems;
    pitItems = newPitItems;
    finalClassStandingItems = newFinalClassStandingItems;
    finalQuizItems = newFinalQuizItems;
    finalExamItems = newFinalExamItems;
    finalPitItems = newFinalPitItems;

    // Reinitialize calculator with new data
    _calculator = GradeCalculator(
      classStandingItems: classStandingItems,
      quizPrelimItems: quizPrelimItems,
      midtermExamItems: midtermExamItems,
      pitItems: pitItems,
      finalClassStandingItems: finalClassStandingItems,
      finalQuizItems: finalQuizItems,
      finalExamItems: finalExamItems,
      finalPitItems: finalPitItems,
    );

    notifyListeners();
  }

  @override
  List<DataGridRow> get rows {
    final List<DataGridRow> combinedRows = [];

    // 1) Max Points row
    combinedRows.add(_buildTopLabelsWithMaxPointsRow());

    // 2) Student rows
    combinedRows.addAll(
      students.asMap().entries.map((entry) {
        final index = entry.key;
        final student = entry.value;

        return DataGridRow(
          cells: [
            // Student info
            DataGridCell<int>(columnName: 'no', value: index + 1),
            DataGridCell<String>(
              columnName: 'idNumber',
              value: student['idNumber'] ?? '',
            ),
            DataGridCell<String>(
              columnName: 'name',
              value: _formatStudentName(student['name'] ?? ''),
            ),

            // Class Standing cells
            ...classStandingItems.map((item) {
              String key =
                  '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
              return DataGridCell<String>(
                columnName: 'cs_${item['id']}',
                value: student[key]?.toString() ?? '',
              );
            }),

            // Class Standing Total and CPA
            DataGridCell<String>(
              columnName: 'cs_total',
              value: _calculator.calculateClassStandingTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'cs_percentage',
              value: _calculator.calculateClassStandingPercentage(student),
            ),

            // Quiz/Prelim cells
            ...quizPrelimItems.map((item) {
              String key =
                  '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
              return DataGridCell<String>(
                columnName: 'qp_${item['id']}',
                value: student[key]?.toString() ?? '',
              );
            }),

            // Quiz/Prelim Total and QA
            DataGridCell<String>(
              columnName: 'qp_total',
              value: _calculator.calculateQuizPrelimTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'qp_percentage',
              value: _calculator.calculateQuizPrelimPercentage(student),
            ),

            // Midterm Exam cells
            ...midtermExamItems.map((item) {
              String key =
                  '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
              return DataGridCell<String>(
                columnName: 'me_${item['id']}',
                value: student[key]?.toString() ?? '',
              );
            }),

            // M (Midterm percentage)
            DataGridCell<String>(
              columnName: 'me_percentage',
              value: _calculator.calculateMidtermExamPercentage(student),
            ),

            // PIT cells
            ...pitItems.map((item) {
              String key =
                  '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
              return DataGridCell<String>(
                columnName: 'pit_${item['id']}',
                value: student[key]?.toString() ?? '',
              );
            }),

            // PIT Total and PIT%
            DataGridCell<String>(
              columnName: 'pit_total',
              value: _calculator.calculatePitTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'pit_percentage',
              value: _calculator.calculatePitPercentage(student),
            ),

            // Lecture cells
            DataGridCell<String>(
              columnName: 'mga',
              value: _calculator.calculateMGA(student),
            ),
            DataGridCell<String>(
              columnName: 'mid_lec_grade_point',
              value: _calculator.calculateMidLecGradePoint(student),
            ),
            DataGridCell<String>(
              columnName: 'mid_grade_point',
              value: _calculator.calculateMidGradePoint(student),
            ),
            DataGridCell<String>(
              columnName: 'midterm_grade',
              value: _calculator.calculateMidtermGrade(student),
            ),

            // Final Class Standing cells
            ...finalClassStandingItems.map((item) {
              String key =
                  '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
              return DataGridCell<String>(
                columnName: 'fcs_${item['id']}',
                value: student[key]?.toString() ?? '',
              );
            }),

            // Final Class Standing Total and CPA
            DataGridCell<String>(
              columnName: 'fcs_total',
              value: _calculator.calculateFinalClassStandingTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'fcs_percentage',
              value: _calculator.calculateFinalClassStandingPercentage(student),
            ),

            // Final Quiz cells
            ...finalQuizItems.map((item) {
              String key =
                  '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
              return DataGridCell<String>(
                columnName: 'fq_${item['id']}',
                value: student[key]?.toString() ?? '',
              );
            }),

            // Final Quiz Total and QA
            DataGridCell<String>(
              columnName: 'fq_total',
              value: _calculator.calculateFinalQuizTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'fq_percentage',
              value: _calculator.calculateFinalQuizPercentage(student),
            ),

            // Final Exam cells
            ...finalExamItems.map((item) {
              String key =
                  '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
              return DataGridCell<String>(
                columnName: 'fe_${item['id']}',
                value: student[key]?.toString() ?? '',
              );
            }),

            // F (Final percentage)
            DataGridCell<String>(
              columnName: 'fe_percentage',
              value: _calculator.calculateFinalExamPercentage(student),
            ),

            // Final PIT cells
            ...finalPitItems.map((item) {
              String key =
                  '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
              return DataGridCell<String>(
                columnName: 'fpit_${item['id']}',
                value: student[key]?.toString() ?? '',
              );
            }),

            // Final PIT Total and PIT%
            DataGridCell<String>(
              columnName: 'fpit_total',
              value: _calculator.calculateFinalPitTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'fpit_percentage',
              value: _calculator.calculateFinalPitPercentage(student),
            ),

            // Final Lecture cells
            DataGridCell<String>(
              columnName: 'fga',
              value: _calculator.calculateFinalMGA(student),
            ),
            DataGridCell<String>(
              columnName: 'final_lec_grade_point',
              value: _calculator.calculateFinalLecGradePoint(student),
            ),
            DataGridCell<String>(
              columnName: 'final_grade_point',
              value: _calculator.calculateFinalGradePoint(student),
            ),
            DataGridCell<String>(
              columnName: 'final_grade',
              value: _calculator.calculateFinalGrade(student),
            ),

            // Computed Final Grade cells
            DataGridCell<String>(
              columnName: 'comp_half_mtg_ftg',
              value: _calculator.calculateHalfMtgFtg(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_12_mtg_ftg_removal',
              value: _calculator.calculateComp12MTGFTGRemoval(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_12_mtg_ftg_after',
              value: _calculator.calculateComp12MTGFTGAfter(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_12_desc',
              value: _calculator.calculateComp12Desc(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_13_mtg_ftg',
              value: _calculator.calculateComp13MTGFTG(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_13_mtg_ftg_removal',
              value: _calculator.calculateComp13MTGFTGRemoval(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_13_mtg_ftg_after',
              value: _calculator.calculateComp13MTGFTGAfter(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_13_desc',
              value: _calculator.calculateComp13Desc(student),
            ),
          ],
        );
      }),
    );

    return combinedRows;
  }

  DataGridRow _buildTopLabelsWithMaxPointsRow() {
    // Build the top frozen row: first three cells are labels (No., ID Number, Names),
    // followed by per-item Max Points and group totals/percentages
    final List<DataGridCell> cells = [];

    // Info columns (titles)
    cells.add(const DataGridCell<String>(columnName: 'no', value: 'No.'));
    cells.add(
      const DataGridCell<String>(columnName: 'idNumber', value: 'ID Number'),
    );
    cells.add(const DataGridCell<String>(columnName: 'name', value: 'Names'));

    // Class Standing max points
    for (var item in classStandingItems) {
      cells.add(
        DataGridCell<String>(
          columnName: 'cs_${item['id']}',
          value: (item['points'] as int? ?? 0).toString(),
        ),
      );
    }
    // Class Standing total and CPA max
    final int csMaxTotal = classStandingItems.fold(
      0,
      (sum, it) => sum + (it['points'] as int? ?? 0),
    );
    cells.add(
      DataGridCell<String>(
        columnName: 'cs_total',
        value: csMaxTotal.toString(),
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'cs_percentage', value: '100%'),
    );

    // Quiz/Prelim max points
    for (var item in quizPrelimItems) {
      cells.add(
        DataGridCell<String>(
          columnName: 'qp_${item['id']}',
          value: (item['points'] as int? ?? 0).toString(),
        ),
      );
    }
    final int qpMaxTotal = quizPrelimItems.fold(
      0,
      (sum, it) => sum + (it['points'] as int? ?? 0),
    );
    cells.add(
      DataGridCell<String>(
        columnName: 'qp_total',
        value: qpMaxTotal.toString(),
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'qp_percentage', value: '100%'),
    );

    // Midterm Exam max points
    for (var item in midtermExamItems) {
      cells.add(
        DataGridCell<String>(
          columnName: 'me_${item['id']}',
          value: (item['points'] as int? ?? 0).toString(),
        ),
      );
    }
    cells.add(
      const DataGridCell<String>(columnName: 'me_percentage', value: '100%'),
    );

    // PIT max points
    for (var item in pitItems) {
      cells.add(
        DataGridCell<String>(
          columnName: 'pit_${item['id']}',
          value: (item['points'] as int? ?? 0).toString(),
        ),
      );
    }
    final int pitMaxTotal = pitItems.fold(
      0,
      (sum, it) => sum + (it['points'] as int? ?? 0),
    );
    cells.add(
      DataGridCell<String>(
        columnName: 'pit_total',
        value: pitMaxTotal.toString(),
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'pit_percentage', value: '100%'),
    );

    // Lecture columns (max points)
    cells.add(const DataGridCell<String>(columnName: 'mga', value: '100%'));
    cells.add(
      const DataGridCell<String>(
        columnName: 'mid_lec_grade_point',
        value: '1.000',
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'mid_grade_point', value: '1.000'),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'midterm_grade', value: '1.00'),
    );

    // Final Class Standing max points
    for (var item in finalClassStandingItems) {
      cells.add(
        DataGridCell<String>(
          columnName: 'fcs_${item['id']}',
          value: (item['points'] as int? ?? 0).toString(),
        ),
      );
    }
    final int fcsMaxTotal = finalClassStandingItems.fold(
      0,
      (sum, it) => sum + (it['points'] as int? ?? 0),
    );
    cells.add(
      DataGridCell<String>(
        columnName: 'fcs_total',
        value: fcsMaxTotal.toString(),
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'fcs_percentage', value: '100%'),
    );

    // Final Quiz max points
    for (var item in finalQuizItems) {
      cells.add(
        DataGridCell<String>(
          columnName: 'fq_${item['id']}',
          value: (item['points'] as int? ?? 0).toString(),
        ),
      );
    }
    final int fqMaxTotal = finalQuizItems.fold(
      0,
      (sum, it) => sum + (it['points'] as int? ?? 0),
    );
    cells.add(
      DataGridCell<String>(
        columnName: 'fq_total',
        value: fqMaxTotal.toString(),
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'fq_percentage', value: '100%'),
    );

    // Final Exam max points
    for (var item in finalExamItems) {
      cells.add(
        DataGridCell<String>(
          columnName: 'fe_${item['id']}',
          value: (item['points'] as int? ?? 0).toString(),
        ),
      );
    }
    cells.add(
      const DataGridCell<String>(columnName: 'fe_percentage', value: '100%'),
    );

    // Final PIT max points
    for (var item in finalPitItems) {
      cells.add(
        DataGridCell<String>(
          columnName: 'fpit_${item['id']}',
          value: (item['points'] as int? ?? 0).toString(),
        ),
      );
    }
    final int fpitMaxTotal = finalPitItems.fold(
      0,
      (sum, it) => sum + (it['points'] as int? ?? 0),
    );
    cells.add(
      DataGridCell<String>(
        columnName: 'fpit_total',
        value: fpitMaxTotal.toString(),
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'fpit_percentage', value: '100%'),
    );

    // Final Lecture columns (max points)
    cells.add(const DataGridCell<String>(columnName: 'fga', value: '100%'));
    cells.add(
      const DataGridCell<String>(
        columnName: 'final_lec_grade_point',
        value: '1.000',
      ),
    );
    cells.add(
      const DataGridCell<String>(
        columnName: 'final_grade_point',
        value: '1.000',
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'final_grade', value: '1.00'),
    );

    // Computed Final Grade max points
    cells.add(
      const DataGridCell<String>(
        columnName: 'comp_half_mtg_ftg',
        value: '1.00',
      ),
    );
    cells.add(
      const DataGridCell<String>(
        columnName: 'comp_12_mtg_ftg_removal',
        value: '1.00',
      ),
    );
    cells.add(
      const DataGridCell<String>(
        columnName: 'comp_12_mtg_ftg_after',
        value: '1.00',
      ),
    );
    cells.add(
      const DataGridCell<String>(
        columnName: 'comp_12_desc',
        value: 'Excellent',
      ),
    );
    cells.add(
      const DataGridCell<String>(columnName: 'comp_13_mtg_ftg', value: '1.00'),
    );
    cells.add(
      const DataGridCell<String>(
        columnName: 'comp_13_mtg_ftg_removal',
        value: '1.00',
      ),
    );
    cells.add(
      const DataGridCell<String>(
        columnName: 'comp_13_mtg_ftg_after',
        value: '1.00',
      ),
    );
    cells.add(
      const DataGridCell<String>(
        columnName: 'comp_13_desc',
        value: 'Excellent',
      ),
    );

    return DataGridRow(cells: cells);
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final isTopLabelPointsRow = row.getCells().any(
      (c) => c.columnName == 'no' && (c.value?.toString() ?? '') == 'No.',
    );

    return DataGridRowAdapter(
      color: isTopLabelPointsRow ? Colors.grey.shade200 : null,
      cells:
          row.getCells().map<Widget>((dataGridCell) {
            final bool emphasize =
                isTopLabelPointsRow ||
                dataGridCell.columnName.endsWith('_total') ||
                dataGridCell.columnName.endsWith('_percentage') ||
                dataGridCell.columnName == 'me_percentage' ||
                dataGridCell.columnName == 'pit_percentage' ||
                dataGridCell.columnName == 'fe_percentage' ||
                dataGridCell.columnName == 'fpit_percentage';

            // Determine text color for computed grades
            Color? textColor;
            if (dataGridCell.columnName.startsWith('comp_')) {
              if (dataGridCell.columnName.endsWith('_desc')) {
                // Description cells - color based on value
                final value = dataGridCell.value.toString().toLowerCase();
                if (value == 'excellent' || value == 'passed') {
                  textColor = Colors.green;
                } else if (value == 'failed') {
                  textColor = Colors.red;
                }
              } else {
                // Grade cells - color based on numeric value
                final value =
                    double.tryParse(dataGridCell.value.toString()) ?? 5.00;
                if (value <= 1.00) {
                  textColor = Colors.green;
                } else if (value <= 3.00) {
                  textColor = Colors.black;
                } else {
                  textColor = Colors.red;
                }
              }
            }

            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Text(
                dataGridCell.value.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: emphasize ? FontWeight.w600 : FontWeight.normal,
                  color: textColor,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
                textAlign:
                    dataGridCell.columnName == 'name'
                        ? TextAlign.left
                        : TextAlign.center,
              ),
            );
          }).toList(),
    );
  }
}
