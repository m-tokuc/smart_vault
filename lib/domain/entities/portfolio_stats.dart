class PortfolioStats {
  final double totalBalance;
  final double totalProfitLoss;
  final double totalInvested;
  final double riskScore; // 0-10
  final Map<String, double> sectorDistribution; // "Technology": 0.5 (50%)
  final double diversityScore; // 0-100 (Higher is better)

  const PortfolioStats({
    this.totalBalance = 0.0,
    this.totalProfitLoss = 0.0,
    this.totalInvested = 0.0,
    this.riskScore = 0.0,
    this.sectorDistribution = const {},
    this.diversityScore = 0.0,
  });

  @override
  String toString() {
    return 'PortfolioStats(balance: $totalBalance, pl: $totalProfitLoss, risk: $riskScore, sectors: $sectorDistribution)';
  }
}
