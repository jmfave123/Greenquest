import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

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
        allowSorting: true,
        allowMultiColumnSorting: true,
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
            'Mid Lec Grade Poi',
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
    List<String> columns = [];
    for (var item in widget.classStandingItems) {
      columns.add('cs_${item['id']}');
    }
    columns.addAll(['cs_total', 'cs_percentage']);
    return columns;
  }

  List<String> _getQuizPrelimColumnNames() {
    List<String> columns = [];
    for (var item in widget.quizPrelimItems) {
      columns.add('qp_${item['id']}');
    }
    columns.addAll(['qp_total', 'qp_percentage']);
    return columns;
  }

  List<String> _getMidtermExamColumnNames() {
    List<String> columns = [];
    for (var item in widget.midtermExamItems) {
      columns.add('me_${item['id']}');
    }
    columns.add('me_percentage');
    return columns;
  }

  List<String> _getPitColumnNames() {
    List<String> columns = [];
    for (var item in widget.pitItems) {
      columns.add('pit_${item['id']}');
    }
    columns.addAll(['pit_total', 'pit_percentage']);
    return columns;
  }

  List<String> _getLectureColumnNames() {
    return ['mga', 'mid_lec_grade_point', 'mid_grade_point', 'midterm_grade'];
  }

  List<String> _getStudentInfoColumnNames() {
    return ['no', 'idNumber', 'name'];
  }

  List<String> _getGradedItemsColumnNames() {
    List<String> columns = [];

    // Class Standing columns
    for (var item in widget.classStandingItems) {
      columns.add('cs_${item['id']}');
    }
    columns.addAll(['cs_total', 'cs_percentage']);

    // Quiz/Prelim columns
    for (var item in widget.quizPrelimItems) {
      columns.add('qp_${item['id']}');
    }
    columns.addAll(['qp_total', 'qp_percentage']);

    // Midterm Exam columns
    for (var item in widget.midtermExamItems) {
      columns.add('me_${item['id']}');
    }
    columns.add('me_percentage');

    // PIT columns
    for (var item in widget.pitItems) {
      columns.add('pit_${item['id']}');
    }
    columns.addAll(['pit_total', 'pit_percentage']);

    // Lecture columns
    columns.addAll([
      'mga',
      'mid_lec_grade_point',
      'mid_grade_point',
      'midterm_grade',
    ]);

    return columns;
  }

  List<String> _getFinalGradedItemsColumnNames() {
    List<String> columns = [];

    // Final Class Standing columns
    for (var item in widget.finalClassStandingItems) {
      columns.add('fcs_${item['id']}');
    }
    columns.addAll(['fcs_total', 'fcs_percentage']);

    // Final Quiz columns
    for (var item in widget.finalQuizItems) {
      columns.add('fq_${item['id']}');
    }
    columns.addAll(['fq_total', 'fq_percentage']);

    // Final Exam columns
    for (var item in widget.finalExamItems) {
      columns.add('fe_${item['id']}');
    }
    columns.add('fe_percentage');

    // Final PIT columns
    for (var item in widget.finalPitItems) {
      columns.add('fpit_${item['id']}');
    }
    columns.addAll(['fpit_total', 'fpit_percentage']);

    // Final Lecture columns
    columns.addAll([
      'fga',
      'final_lec_grade_point',
      'final_grade_point',
      'final_grade',
    ]);

    return columns;
  }

  List<String> _getFinalClassStandingColumnNames() {
    List<String> columns = [];
    for (var item in widget.finalClassStandingItems) {
      columns.add('fcs_${item['id']}');
    }
    columns.addAll(['fcs_total', 'fcs_percentage']);
    return columns;
  }

  List<String> _getFinalQuizColumnNames() {
    List<String> columns = [];
    for (var item in widget.finalQuizItems) {
      columns.add('fq_${item['id']}');
    }
    columns.addAll(['fq_total', 'fq_percentage']);
    return columns;
  }

  List<String> _getFinalExamColumnNames() {
    List<String> columns = [];
    for (var item in widget.finalExamItems) {
      columns.add('fe_${item['id']}');
    }
    columns.add('fe_percentage');
    return columns;
  }

  List<String> _getFinalPitColumnNames() {
    List<String> columns = [];
    for (var item in widget.finalPitItems) {
      columns.add('fpit_${item['id']}');
    }
    columns.addAll(['fpit_total', 'fpit_percentage']);
    return columns;
  }

  List<String> _getFinalLectureColumnNames() {
    return ['fga', 'final_lec_grade_point', 'final_grade_point', 'final_grade'];
  }

  List<String> _getComputedFinalGradeColumnNames() {
    return [
      'comp_half_mtg_ftg',
      'comp_12_mtg_ftg_removal',
      'comp_12_mtg_ftg_after',
      'comp_12_desc',
      'comp_13_mtg_ftg',
      'comp_13_mtg_ftg_removal',
      'comp_13_mtg_ftg_after',
      'comp_13_desc',
    ];
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

  /// Format name from "First Last" to "Last, First" format
  String _formatStudentName(String name) {
    if (name.isEmpty) return '';

    final parts = name.trim().split(' ');
    if (parts.length < 2) return name; // Return as-is if only one part

    // Get the last part (last name) and all other parts (first/middle names)
    final lastName = parts.last;
    final firstMiddleNames = parts.take(parts.length - 1).join(' ');

    return '$lastName, $firstMiddleNames';
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
  });

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
              value: _calculateClassStandingTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'cs_percentage',
              value: _calculateClassStandingPercentage(student),
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
              value: _calculateQuizPrelimTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'qp_percentage',
              value: _calculateQuizPrelimPercentage(student),
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
              value: _calculateMidtermExamPercentage(student),
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
              value: _calculatePitTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'pit_percentage',
              value: _calculatePitPercentage(student),
            ),

            // Lecture cells
            DataGridCell<String>(
              columnName: 'mga',
              value: _calculateMGA(student),
            ),
            DataGridCell<String>(
              columnName: 'mid_lec_grade_point',
              value: _calculateMidLecGradePoint(student),
            ),
            DataGridCell<String>(
              columnName: 'mid_grade_point',
              value: _calculateMidGradePoint(student),
            ),
            DataGridCell<String>(
              columnName: 'midterm_grade',
              value: _calculateMidtermGrade(student),
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
              value: _calculateFinalClassStandingTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'fcs_percentage',
              value: _calculateFinalClassStandingPercentage(student),
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
              value: _calculateFinalQuizTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'fq_percentage',
              value: _calculateFinalQuizPercentage(student),
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
              value: _calculateFinalExamPercentage(student),
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
              value: _calculateFinalPitTotal(student),
            ),
            DataGridCell<String>(
              columnName: 'fpit_percentage',
              value: _calculateFinalPitPercentage(student),
            ),

            // Final Lecture cells
            DataGridCell<String>(
              columnName: 'fga',
              value: _calculateFinalMGA(student),
            ),
            DataGridCell<String>(
              columnName: 'final_lec_grade_point',
              value: _calculateFinalLecGradePoint(student),
            ),
            DataGridCell<String>(
              columnName: 'final_grade_point',
              value: _calculateFinalGradePoint(student),
            ),
            DataGridCell<String>(
              columnName: 'final_grade',
              value: _calculateFinalGrade(student),
            ),

            // Computed Final Grade cells
            DataGridCell<String>(
              columnName: 'comp_half_mtg_ftg',
              value: _calculateHalfMtgFtg(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_12_mtg_ftg_removal',
              value: _calculateComp12MTGFTGRemoval(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_12_mtg_ftg_after',
              value: _calculateComp12MTGFTGAfter(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_12_desc',
              value: _calculateComp12Desc(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_13_mtg_ftg',
              value: _calculateComp13MTGFTG(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_13_mtg_ftg_removal',
              value: _calculateComp13MTGFTGRemoval(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_13_mtg_ftg_after',
              value: _calculateComp13MTGFTGAfter(student),
            ),
            DataGridCell<String>(
              columnName: 'comp_13_desc',
              value: _calculateComp13Desc(student),
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

  // Calculation methods
  String _calculateClassStandingTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in classStandingItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String _calculateClassStandingPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(_calculateClassStandingTotal(student)) ?? 0;
    int maxTotal = classStandingItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String _calculateQuizPrelimTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in quizPrelimItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String _calculateQuizPrelimPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(_calculateQuizPrelimTotal(student)) ?? 0;
    int maxTotal = quizPrelimItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String _calculatePitTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in pitItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String _calculatePitPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(_calculatePitTotal(student)) ?? 0;
    int maxTotal = pitItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String _calculateMidtermExamPercentage(Map<String, dynamic> student) {
    int total = 0;
    for (var item in midtermExamItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    int maxTotal = midtermExamItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  // Helper methods to get category score as fraction (not formatted/rounded)
  double _classStandingFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in classStandingItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = classStandingItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _quizPrelimFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in quizPrelimItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = quizPrelimItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _midtermExamFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in midtermExamItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = midtermExamItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _pitFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in pitItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = pitItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  // Calculate MGA using raw fractions
  double _calculateRawMGA(Map<String, dynamic> student) {
    double cpa = _classStandingFraction(student);
    double qa = _quizPrelimFraction(student);
    double m = _midtermExamFraction(student);
    double pit = _pitFraction(student);
    return 0.10 * cpa + 0.40 * qa + 0.30 * m + 0.20 * pit;
  }

  // Display MGA as whole percent (as before)
  String _calculateMGA(Map<String, dynamic> student) {
    double mga = _calculateRawMGA(student);
    return '${(mga * 100).round()}%'; // as whole percent
  }

  String _calculateMidLecGradePoint(Map<String, dynamic> student) {
    double mgaValue = _calculateRawMGA(
      student,
    ); // true fraction, not percent string
    double maxMgaValue = 1.0; // Always 1.0 for full scale
    double ratio = (maxMgaValue == 0) ? 0 : mgaValue / maxMgaValue;
    double gradePoint;
    if (ratio >= 0.7) {
      gradePoint = (23.0 / 3.0) - (20.0 / 3.0) * ratio;
    } else {
      gradePoint = 5.0 - (20.0 / 7.0) * ratio;
    }
    return gradePoint.toStringAsFixed(3); // Use rounding for Excel match
  }

  // Mid Grade Point always equals Mid Lec Grade Point
  String _calculateMidGradePoint(Map<String, dynamic> student) {
    return _calculateMidLecGradePoint(student);
  }

  // Each bracket: [lower, upper, grade]
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

  String _getMidtermGradeEquivalent(double gradePoint) {
    for (var range in _midtermGradeIntervals) {
      if (gradePoint >= range[0] && gradePoint < range[1]) {
        return range[2].toStringAsFixed(2);
      }
    }
    return '5.00';
  }

  String _calculateMidtermGrade(Map<String, dynamic> student) {
    double gradePoint =
        double.tryParse(_calculateMidGradePoint(student)) ?? 0.0;
    gradePoint = double.parse(gradePoint.toStringAsFixed(3));
    return _getMidtermGradeEquivalent(gradePoint);
  }

  // Final Grade Calculations
  String _calculateFinalClassStandingTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalClassStandingItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String _calculateFinalClassStandingPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(_calculateFinalClassStandingTotal(student)) ?? 0;
    int maxTotal = finalClassStandingItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String _calculateFinalQuizTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalQuizItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String _calculateFinalQuizPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(_calculateFinalQuizTotal(student)) ?? 0;
    int maxTotal = finalQuizItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String _calculateFinalExamPercentage(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalExamItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    int maxTotal = finalExamItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String _calculateFinalPitTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalPitItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String _calculateFinalPitPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(_calculateFinalPitTotal(student)) ?? 0;
    int maxTotal = finalPitItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  // Helper methods to get Final Grade category score as fraction
  double _finalClassStandingFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalClassStandingItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = finalClassStandingItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _finalQuizFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalQuizItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = finalQuizItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _finalExamFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalExamItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = finalExamItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _finalPitFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalPitItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = finalPitItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  // Calculate Final MGA using raw fractions
  double _calculateFinalRawMGA(Map<String, dynamic> student) {
    double cpa = _finalClassStandingFraction(student);
    double qa = _finalQuizFraction(student);
    double f = _finalExamFraction(student);
    double pit = _finalPitFraction(student);
    return 0.10 * cpa + 0.40 * qa + 0.30 * f + 0.20 * pit;
  }

  // Display Final MGA as whole percent
  String _calculateFinalMGA(Map<String, dynamic> student) {
    double mga = _calculateFinalRawMGA(student);
    return '${(mga * 100).round()}%';
  }

  String _calculateFinalLecGradePoint(Map<String, dynamic> student) {
    double mgaValue = _calculateFinalRawMGA(student);
    double maxMgaValue = 1.0;
    double ratio = (maxMgaValue == 0) ? 0 : mgaValue / maxMgaValue;
    double gradePoint;
    if (ratio >= 0.7) {
      gradePoint = (23.0 / 3.0) - (20.0 / 3.0) * ratio;
    } else {
      gradePoint = 5.0 - (20.0 / 7.0) * ratio;
    }
    return gradePoint.toStringAsFixed(3);
  }

  // Final Grade Point always equals Final Lec Grade Point
  String _calculateFinalGradePoint(Map<String, dynamic> student) {
    return _calculateFinalLecGradePoint(student);
  }

  // Computed Final Grade Calculations
  String _calculateComp12MTGFTG(Map<String, dynamic> student) {
    double mtg = double.tryParse(_calculateMidtermGrade(student)) ?? 5.00;
    double ftg = double.tryParse(_calculateFinalGrade(student)) ?? 5.00;
    double result = (0.5 * mtg) + (0.5 * ftg);
    return result.toStringAsFixed(2);
  }

  String _calculateComp12MTGFTGRemoval(Map<String, dynamic> student) {
    double result = double.tryParse(_calculateComp12MTGFTG(student)) ?? 5.00;
    // If result is 4.50 or below, show 5.00, otherwise show result
    if (result <= 4.50) {
      return '5.00';
    }
    return result.toStringAsFixed(2);
  }

  String _calculateComp12MTGFTGAfter(Map<String, dynamic> student) {
    // For removal grades, always 5.00 in the image
    return _calculateComp12MTGFTGRemoval(student);
  }

  String _calculateComp12Desc(Map<String, dynamic> student) {
    double result = double.tryParse(_calculateComp12MTGFTG(student)) ?? 5.00;
    if (result <= 1.00) return 'Excellent';
    if (result <= 2.99) return 'Passed';
    return 'Failed';
  }

  String _calculateComp13MTGFTG(Map<String, dynamic> student) {
    double mtg = double.tryParse(_calculateMidtermGrade(student)) ?? 5.00;
    double ftg = double.tryParse(_calculateFinalGrade(student)) ?? 5.00;
    double result = (1.0 / 3.0 * mtg) + (2.0 / 3.0 * ftg);
    return result.toStringAsFixed(2);
  }

  String _calculateComp13MTGFTGRemoval(Map<String, dynamic> student) {
    double result = double.tryParse(_calculateComp13MTGFTG(student)) ?? 5.00;
    // If result is 4.50 or below, show 5.00, otherwise show result
    if (result <= 4.50) {
      return '5.00';
    }
    return result.toStringAsFixed(2);
  }

  String _calculateComp13MTGFTGAfter(Map<String, dynamic> student) {
    // For removal grades, always 5.00 in the image
    return _calculateComp13MTGFTGRemoval(student);
  }

  String _calculateComp13Desc(Map<String, dynamic> student) {
    double result = double.tryParse(_calculateComp13MTGFTG(student)) ?? 5.00;
    if (result <= 1.00) return 'Excellent';
    if (result <= 2.99) return 'Passed';
    return 'Failed';
  }

  String _calculateFinalGrade(Map<String, dynamic> student) {
    double gradePoint =
        double.tryParse(_calculateFinalGradePoint(student)) ?? 0.0;
    gradePoint = double.parse(gradePoint.toStringAsFixed(3));
    return _getMidtermGradeEquivalent(gradePoint);
  }

  // Computed Final Grade: 1/2 MTG + 1/2 FTG (used by computed section)
  String _calculateHalfMtgFtg(Map<String, dynamic> student) {
    double mtg = double.tryParse(_calculateMidtermGrade(student)) ?? 0.0;
    double ftg = double.tryParse(_calculateFinalGrade(student)) ?? 0.0;
    double combined = 0.5 * mtg + 0.5 * ftg;
    return combined.toStringAsFixed(2);
  }

  // 1/2 MTG + 1/2 FTG (For Removal):
  // IF(VLOOKUP(avg, table, 2, TRUE) > 3.5, 5, VLOOKUP(avg, table, 2, TRUE))
  String _calculateComp12MTGFTGForRemoval(Map<String, dynamic> student) {
    double avg = double.tryParse(_calculateComp12MTGFTG(student)) ?? 5.00;
    // Map through the same intervals used for midterm to normalize to grade ladder
    String mapped = _getMidtermGradeEquivalent(
      double.parse(avg.toStringAsFixed(3)),
    );
    double mappedNum = double.tryParse(mapped) ?? 5.00;
    if (mappedNum > 3.50) {
      return '5.00';
    }
    return mapped;
  }

  // 1/2 MTG + 1/2 FTG (After Removal): just copy the For Removal value
  String _calculateComp12MTGFTGAfterRemoval(Map<String, dynamic> student) {
    return _calculateComp12MTGFTGForRemoval(student);
  }

  // 1/3 MTG + 2/3 FTG (For Removal): cap to 5.00 if mapped > 3.50
  String _calculateComp13MTGFTGForRemoval(Map<String, dynamic> student) {
    double avg = double.tryParse(_calculateComp13MTGFTG(student)) ?? 5.00;
    String mapped = _getMidtermGradeEquivalent(
      double.parse(avg.toStringAsFixed(3)),
    );
    double mappedNum = double.tryParse(mapped) ?? 5.00;
    if (mappedNum > 3.50) {
      return '5.00';
    }
    return mapped;
  }

  // 1/3 MTG + 2/3 FTG (After Removal): copy For Removal
  String _calculateComp13MTGFTGAfterRemoval(Map<String, dynamic> student) {
    return _calculateComp13MTGFTGForRemoval(student);
  }
}
