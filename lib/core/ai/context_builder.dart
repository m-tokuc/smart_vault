import '../../domain/entities/investment_asset.dart';
import '../../domain/entities/portfolio_stats.dart';
import 'package:intl/intl.dart';

class PortfolioContextBuilder {
  String buildPortfolioContext(
      List<InvestmentAsset> assets, PortfolioStats stats) {
    final buffer = StringBuffer();
    final fmt = NumberFormat.compactCurrency(symbol: '\$');

    buffer.writeln("Unknown User Portfolio Analysis Request.");
    buffer.writeln("Date: ${DateTime.now().toIso8601String()}");
    buffer.writeln("--- PORTFOLIO SUMMARY ---");
    buffer.writeln("Total Value: ${fmt.format(stats.totalBalance)}");
    buffer.writeln("Total Profit/Loss: ${fmt.format(stats.totalProfitLoss)}");
    buffer.writeln("Risk Score: ${stats.riskScore}/10");
    buffer.writeln("Diversity Score: ${stats.diversityScore}/100");
    buffer.writeln("");

    buffer.writeln("--- ASSET BREAKDOWN ---");
    for (var asset in assets) {
      // Anonymized: No user ID, just Ticker and Type
      final plPercent = asset.averagePrice > 0
          ? ((asset.currentPrice! - asset.averagePrice) /
                  asset.averagePrice *
                  100)
              .toStringAsFixed(1)
          : "0.0";

      buffer.writeln(
          "- ${asset.symbol} (${asset.type.name.toUpperCase()}): \$${asset.totalValue.toStringAsFixed(0)} value. P/L: $plPercent%. Sector: ${asset.sector ?? 'Unknown'}.");
    }

    buffer.writeln("");
    buffer.writeln("--- SECTOR DISTRIBUTION ---");
    stats.sectorDistribution.forEach((sector, percent) {
      buffer.writeln("- $sector: ${(percent * 100).toStringAsFixed(1)}%");
    });

    return buffer.toString();
  }

  String appendNewsContext(String baseContext, List<String> newsHeadlines) {
    if (newsHeadlines.isEmpty) return baseContext;

    final buffer = StringBuffer(baseContext);
    buffer.writeln("");
    buffer.writeln("--- RECENT MARKET NEWS ---");
    for (var news in newsHeadlines) {
      buffer.writeln("- $news");
    }
    return buffer.toString();
  }
}
