import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'skeleton_loading.dart';

/// Reusable Monthly Tree Planting Trends Chart
/// Shows tree planting data aggregated by month for a given year
class MonthlyTreeTrendsChart extends StatefulWidget {
  const MonthlyTreeTrendsChart({
    super.key,
    this.year,
    this.title = 'Monthly Tree Planting Trends',
    this.instructorId,
    this.sectionName,
  });

  /// Year to display (defaults to current year)
  final int? year;

  /// Chart title
  final String title;

  /// Optional: Filter by instructor ID
  final String? instructorId;

  /// Optional: Filter by section name
  final String? sectionName;

  @override
  State<MonthlyTreeTrendsChart> createState() => _MonthlyTreeTrendsChartState();
}

class _MonthlyTreeTrendsChartState extends State<MonthlyTreeTrendsChart> {
  bool _isLoading = true;
  String? _error;
  List<int> _monthlyData = List.filled(12, 0);
  int _totalTrees = 0;

  @override
  void initState() {
    super.initState();
    _loadTreeData();
  }

  Future<void> _loadTreeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final year = widget.year ?? DateTime.now().year;
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      // Build query
      Query query = FirebaseFirestore.instance
          .collection('submissions')
          .where('activityType', isEqualTo: 'tree_planting')
          .where('status', isEqualTo: 'approved');

      // Add optional filters
      if (widget.instructorId != null) {
        query = query.where('instructorId', isEqualTo: widget.instructorId);
      }
      if (widget.sectionName != null) {
        query = query.where('sectionName', isEqualTo: widget.sectionName);
      }

      final snapshot = await query.get();

      // Initialize monthly totals
      final monthlyTotals = List.filled(12, 0);
      int total = 0;

      // Process each submission
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final plantDate = data['plantDate'];
        final quantity = data['quantity'] as int? ?? 1;

        DateTime? date;
        if (plantDate is Timestamp) {
          date = plantDate.toDate();
        } else if (plantDate is String) {
          try {
            date = DateTime.parse(plantDate);
          } catch (e) {
            continue; // Skip invalid dates
          }
        }

        // Only count if in the target year
        if (date != null &&
            date.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfYear.add(const Duration(days: 1)))) {
          final monthIndex = date.month - 1; // 0-indexed
          monthlyTotals[monthIndex] += quantity;
          total += quantity;
        }
      }

      if (mounted) {
        setState(() {
          _monthlyData = monthlyTotals;
          _totalTrees = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Log error without using print in production
      if (mounted) {
        setState(() {
          _error = 'Failed to load tree data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          color: Color(0xFF34A853),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly trend for ${widget.year ?? DateTime.now().year} ($_totalTrees total)',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadTreeData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart or Loading/Error state
            SizedBox(
              height: 280,
              child:
                  _isLoading
                      ? const SkeletonChartArea()
                      : _error != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                      : _totalTrees == 0
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No tree planting data for ${widget.year ?? DateTime.now().year}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                      : _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final maxValue = _monthlyData.reduce((a, b) => a > b ? a : b).toDouble();
    final average = _totalTrees / 12;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const months = [
                  'JAN',
                  'FEB',
                  'MAR',
                  'APR',
                  'MAY',
                  'JUN',
                  'JUL',
                  'AUG',
                  'SEP',
                  'OCT',
                  'NOV',
                  'DEC',
                ];
                if (value.toInt() >= 0 && value.toInt() < 12) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[value.toInt()],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxValue > 0 ? maxValue / 4 : 5,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxValue > 0 ? maxValue * 1.2 : 10,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              12,
              (index) =>
                  FlSpot(index.toDouble(), _monthlyData[index].toDouble()),
            ),
            isCurved: true,
            color: const Color(0xFF34A853),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF34A853),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF34A853).withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipColor: (touchedSpot) => Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                const months = [
                  'January',
                  'February',
                  'March',
                  'April',
                  'May',
                  'June',
                  'July',
                  'August',
                  'September',
                  'October',
                  'November',
                  'December',
                ];
                return LineTooltipItem(
                  '${months[spot.x.toInt()]}\n${spot.y.toInt()} trees',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: average,
              color: Colors.orange.withOpacity(0.5),
              strokeWidth: 2,
              dashArray: [8, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 5),
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => 'Avg: ${average.toStringAsFixed(1)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
