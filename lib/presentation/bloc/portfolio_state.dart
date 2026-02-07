import 'package:equatable/equatable.dart';
import '../../domain/entities/investment_asset.dart';
import '../../domain/entities/portfolio_stats.dart';

/// Base class for Portfolio state.
abstract class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object> get props => [];
}

/// State indicating that portfolio data is currently being fetched.
class PortfolioLoading extends PortfolioState {}

/// State indicating an error occurred while fetching or updating the portfolio.
class PortfolioError extends PortfolioState {
  final String message;

  const PortfolioError(this.message);

  @override
  List<Object> get props => [message];
}

/// State indicating that portfolio data has been successfully loaded.
///
/// Contains the list of [assets] and calculated [stats] (total balance, profit/loss).
class PortfolioLoaded extends PortfolioState {
  final List<InvestmentAsset> assets;
  final PortfolioStats stats;
  final DateTime lastUpdated;

  // Convenience getters for backward compatibility
  double get totalBalance => stats.totalBalance;
  double get totalProfitLoss => stats.totalProfitLoss;

  const PortfolioLoaded({
    required this.assets,
    required this.stats,
    required this.lastUpdated,
  });

  @override
  List<Object> get props => [assets, stats, lastUpdated];
}
