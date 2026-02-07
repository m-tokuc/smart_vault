import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SparklineWidget extends StatelessWidget {
  final List<double> data;
  final bool isPositive;
  final double height;
  final double width;

  const SparklineWidget({
    super.key,
    required this.data,
    required this.isPositive,
    this.height = 40,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.length < 2) {
      return SizedBox(width: width, height: height); // Empty placeholder
    }

    final color =
        isPositive ? const Color(0xFF00BFA5) : const Color(0xFFFF5252);

    // Normalize data for chart if needed, but LineChart handles scale automatically usually.
    // Creating spots
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData:
              const LineTouchData(enabled: false), // Non-interactive sparkline
        ),
      ),
    );
  }
}
