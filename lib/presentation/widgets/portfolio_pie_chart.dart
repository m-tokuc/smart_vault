import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/investment_asset.dart';

class PortfolioPieChart extends StatelessWidget {
  final List<InvestmentAsset> assets;

  const PortfolioPieChart({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();

    double totalValue = 0;
    for (var asset in assets) {
      totalValue += (asset.currentPrice ?? 0.0) * asset.amount;
    }

    // Modern Financial Palette
    final List<Color> palette = [
      const Color(0xFF2962FF), // Electric Blue
      const Color(0xFF00BFA5), // Teal
      const Color(0xFFFFD600), // Yellow
      const Color(0xFFFF5252), // Red
      const Color(0xFF7E57C2), // Deep Purple
      const Color(0xFFFF9100), // Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00E5FF), // Cyan
    ];

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: List.generate(assets.length, (index) {
                final asset = assets[index];
                final value = (asset.currentPrice ?? 0.0) * asset.amount;
                final percentage = (value / totalValue) * 100;
                final color = palette[index % palette.length];

                return PieChartSectionData(
                  color: color,
                  value: value,
                  title:
                      percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                  radius: 55, // Slightly thicker
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: percentage > 10
                      ? _Badge(asset.symbol, size: 30, borderColor: color)
                      : null,
                  badgePositionPercentageOffset: 1.3,
                );
              }),
              sectionsSpace: 4, // More gap for modern look
              centerSpaceRadius: 50,
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Total",
                  style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text("${assets.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 24)),
              const Text("Assets",
                  style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(this.text, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: Text(
          text[0],
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
