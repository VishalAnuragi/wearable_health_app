import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';

enum TimeRange { recent, daily, weekly }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _readings = [];
  bool _isLoading = true;
  TimeRange _selectedRange = TimeRange.recent;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = context.read<DatabaseHelper>();
    List<Map<String, dynamic>> data;

    switch (_selectedRange) {
      case TimeRange.recent:
        data = await db.getRecentReadings(limit: 20);
        data = data.reversed.toList();
        break;
      case TimeRange.daily:
        data = await db.getDailyHistory();
        break;
      case TimeRange.weekly:
        data = await db.getWeeklySummary();
        break;
    }

    setState(() {
      _readings = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health History'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Heart Rate'),
              Tab(text: 'SpO2'),
              Tab(text: 'Steps'),
              Tab(text: 'Battery'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<TimeRange>(
                segments: const [
                  ButtonSegment(value: TimeRange.recent, label: Text('Recent')),
                  ButtonSegment(value: TimeRange.daily, label: Text('Daily')),
                  ButtonSegment(value: TimeRange.weekly, label: Text('Weekly')),
                ],
                selected: {_selectedRange},
                onSelectionChanged: (Set<TimeRange> newSelection) {
                  setState(() {
                    _selectedRange = newSelection.first;
                  });
                  _loadData();
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _readings.isEmpty
                  ? const Center(child: Text('Not enough data recorded yet.'))
                  : TabBarView(
                children: [
                  _buildChartTab('Heart Rate (BPM)', 'heart_rate', Colors.red),
                  _buildChartTab('Blood Oxygen (%)', 'spo2', Colors.blue),
                  _buildChartTab('Step Count', 'steps', Colors.orange),
                  _buildChartTab('Battery Level (%)', 'battery_level', Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab(String title, String dataKey, Color color) {
    if (_readings.isEmpty) return const SizedBox.shrink();

    final double minVal = _readings.map((r) => (r[dataKey] as num).toDouble()).reduce(min);
    final double maxVal = _readings.map((r) => (r[dataKey] as num).toDouble()).reduce(max);

    double padding = (maxVal - minVal) * 0.1;
    if (padding == 0) padding = 5.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minVal - padding,
                maxY: maxVal + padding,
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 45),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= _readings.length) return const Text('');
                        final reading = _readings[value.toInt()];

                        String label = '';
                        // If it's aggregated data, use the SQL time_label. Otherwise, format the raw timestamp.
                        if (reading.containsKey('time_label')) {
                          label = reading['time_label'];
                        } else {
                          final date = DateTime.parse(reading['timestamp']);
                          label = DateFormat('HH:mm:ss').format(date.toLocal());
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(label, style: const TextStyle(fontSize: 10)),
                        );
                      },
                      reservedSize: 35,
                      interval: max(1, (_readings.length / 5).floorToDouble()), // Spread labels evenly
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(_readings.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        (_readings[index][dataKey] as num).toDouble(),
                      );
                    }),
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}