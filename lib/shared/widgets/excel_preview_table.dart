import 'package:flutter/material.dart';

/// Excel-like preview table widget for export preview
/// Displays data in a table format that matches the Excel output structure
class ExcelPreviewTable extends StatelessWidget {
  final List<Map<String, dynamic>> previewData;
  final List<String> columnHeaders;

  const ExcelPreviewTable({
    super.key,
    required this.previewData,
    required this.columnHeaders,
  });

  @override
  Widget build(BuildContext context) {
    if (previewData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No data to preview',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[100]),
                children:
                    columnHeaders.map((header) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Text(
                          header,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
              ),
              // Data rows
              ...previewData.map((row) {
                return TableRow(
                  children:
                      columnHeaders.map((header) {
                        final value =
                            row[header] ?? row[header.toLowerCase()] ?? '';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Text(
                            value.toString(),
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
