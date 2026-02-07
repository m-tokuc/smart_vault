import '../entities/investment_asset.dart';
import '../entities/portfolio_stats.dart';
import 'dart:math';

class CalculatePortfolioStatistics {
  PortfolioStats execute({
    required List<InvestmentAsset> assets,
    required double currencyRate, // 1.0 for USD, approx 35 for TRY
  }) {
    if (assets.isEmpty) {
      return const PortfolioStats();
    }

    double totalValue = 0.0;
    double totalCost = 0.0;

    // Sector Distribution
    final Map<String, double> sectorValue = {};
    final Map<String, double> sectorAlloc = {};

    // Risk Calculation
    double weightedRiskSum = 0.0;

    for (var asset in assets) {
      final currentPriceInRate = (asset.currentPrice ?? 0.0) * currencyRate;
      final avgPriceInRate = asset.averagePrice * currencyRate;

      final assetValue = asset.amount * currentPriceInRate;
      final assetCost = asset.amount * avgPriceInRate;

      totalValue += assetValue;
      totalCost += assetCost;

      // Sector Logic
      final sector = asset.sector ?? _getSectorFallback(asset.type);
      sectorValue[sector] = (sectorValue[sector] ?? 0.0) + assetValue;

      // Risk Logic
      weightedRiskSum += asset.riskScore * assetValue;
    }

    double profitLoss = totalValue - totalCost;

    // Normalize Sector Distribution Percentages
    sectorValue.forEach((key, value) {
      if (totalValue > 0) {
        sectorAlloc[key] = value / totalValue;
      } else {
        sectorAlloc[key] = 0;
      }
    });

    // Final Risk Score Calculation
    double finalRisk = 0.0;
    if (totalValue > 0) {
      finalRisk = weightedRiskSum / totalValue;
    }

    // Concentration Penalty: If any sector > 60%, add penalty
    for (var pct in sectorAlloc.values) {
      if (pct > 0.60) {
        finalRisk = min(10.0, finalRisk * 1.2); // +20% risk
      }
    }

    // Diversity Score (Simple: 100 - (MaxConcentration * 100))
    // Or Simpson/Shannon index but let's keep it simple for UI
    double maxConcentration = 0.0;
    if (sectorAlloc.isNotEmpty) {
      maxConcentration = sectorAlloc.values.reduce(max);
    }
    double diversity = (1.0 - maxConcentration) * 100;
    if (assets.length == 1) diversity = 0; // Only 1 asset = 0 diversity

    return PortfolioStats(
      totalBalance: totalValue,
      totalProfitLoss: profitLoss,
      totalInvested: totalCost,
      riskScore: double.parse(finalRisk.toStringAsFixed(2)),
      sectorDistribution: sectorAlloc,
      diversityScore: double.parse(diversity.toStringAsFixed(1)),
    );
  }

  String _getSectorFallback(AssetType type) {
    switch (type) {
      case AssetType.crypto:
        return 'Crypto';
      case AssetType.stock:
        return 'Technology'; // Fallback assumptions
      case AssetType.metal:
        return 'Commodities';
      case AssetType.forex:
        return 'Currency';
      default:
        return 'Other';
    }
  }
}
