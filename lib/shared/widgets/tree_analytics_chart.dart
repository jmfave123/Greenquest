import 'package:flutter/material.dart';
import 'package:flutter_charts/flutter_charts.dart';

class TreeMetricPoint {
  const TreeMetricPoint({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final Color? color;
}

class TreeAnalyticsChart extends StatelessWidget {
  const TreeAnalyticsChart({
    super.key,
    required this.data,
    this.title = 'Tree Analytics',
    this.subtitle,
    this.seriesLabel = 'Total Trees',
  });

  final List<TreeMetricPoint> data;
  final String title;
  final String? subtitle;
  final String seriesLabel;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    final chartOptions = const ChartOptions();
    final chartData = ChartData(
      dataRows: [data.map((point) => point.value).toList()],
      xUserLabels: data.map((point) => point.label).toList(),
      dataRowsLegends: [seriesLabel],
      chartOptions: chartOptions,
      dataRowsColors: [data.first.color ?? const Color(0xFF34A853)],
    );

    final layoutStrategy = DefaultIterativeLabelLayoutStrategy(
      options: chartOptions,
    );

    final container = VerticalBarChartTopContainer(
      chartData: chartData,
      xContainerLabelLayoutStrategy: layoutStrategy,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, innerConstraints) {
                      final availableWidth =
                          innerConstraints.maxWidth.isFinite
                              ? innerConstraints.maxWidth
                              : 600.0;
                      final minWidth = data.length * 80.0;
                      final width =
                          availableWidth < minWidth ? minWidth : availableWidth;

                      final availableHeight =
                          innerConstraints.maxHeight.isFinite
                              ? innerConstraints.maxHeight
                              : 280.0;
                      final minHeight = 280.0;
                      final height =
                          availableHeight < minHeight
                              ? minHeight
                              : availableHeight;

                      final chart = SizedBox(
                        width: width,
                        height: height,
                        child: VerticalBarChart(
                          painter: VerticalBarChartPainter(
                            verticalBarChartContainer: container,
                          ),
                          size: Size(width, height),
                        ),
                      );

                      return Scrollbar(
                        thumbVisibility: width > availableWidth,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: chart,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );

          if (constraints.maxHeight.isFinite) {
            return Scrollbar(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
                ),
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: const SizedBox(
        height: 200,
        child: Center(child: Text('No tree metrics available yet.')),
      ),
    );
  }
}
