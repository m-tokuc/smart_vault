import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'investment_asset.g.dart';

/// Represents the type of financial asset.
///
/// Used for categorization and determining the visual representation (e.g., icons, units).
@HiveType(typeId: 1)
enum AssetType {
  @HiveField(0)
  crypto,
  @HiveField(1)
  stock,
  @HiveField(2)
  metal,
  @HiveField(3)
  forex,
  @HiveField(4)
  fund,
  @HiveField(5)
  commodity,
  @HiveField(6)
  currency,
  @HiveField(7)
  other
}

/// A core entity representing an asset in the user's portfolio.
///
/// This class handles both persistence via [Hive] (annotated fields) and
/// runtime state (e.g., [isOfflineData]).
/// It extends [Equatable] to facilitate value comparison in Bloc/State management.
@HiveType(typeId: 0)
class InvestmentAsset extends Equatable {
  /// Unique identifier for the asset (e.g. "bitcoin", "AAPL").
  @HiveField(0)
  final String id;

  /// The trading symbol/ticker (e.g. "BTC", "USD").
  @HiveField(1)
  final String symbol;

  /// Full name of the asset (e.g. "Bitcoin", "United States Dollar").
  @HiveField(2)
  final String name;

  /// The quantity held in the portfolio.
  @HiveField(3)
  final double amount;

  /// The average purchase price per unit. Used to calculate Profit/Loss.
  @HiveField(4)
  final double averagePrice;

  /// URL to the asset's logo image.
  @HiveField(5)
  final String? imageUrl;

  /// The current market price. Nullable if data fetch fails.
  @HiveField(6)
  final double? currentPrice;

  /// Percentage price change in the last 24 hours.
  @HiveField(7)
  final double? priceChange24h;

  /// The category of the asset.
  @HiveField(8)
  final AssetType type;

  // --- Pro Features 2.0 Properties ---

  /// The market sector the asset belongs to (e.g. "Technology").
  @HiveField(9)
  final String? sector;

  /// An AI-calculated risk score from 0.0 to 10.0.
  @HiveField(10)
  final double riskScore;

  /// Volatility percentage (0-100).
  @HiveField(11)
  final double volatility;

  /// A list of recent prices for generating sparkline charts.
  @HiveField(12)
  final List<double> lastSevenDaysPrices;

  // --- Runtime State (Not Persisted) ---

  /// Indicates if the data is served from offline cache.
  /// Not annotated with @HiveField, so it is transient.
  final bool isOfflineData;

  /// The exchange rate helper for multi-currency support.
  final double currencyRate;

  const InvestmentAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.amount,
    required this.averagePrice,
    this.imageUrl,
    this.currentPrice,
    this.priceChange24h,
    this.type = AssetType.crypto,
    this.currencyRate = 1.0,
    this.sector,
    this.riskScore = 5.0, // Default to medium risk
    this.volatility = 0.0,
    this.lastSevenDaysPrices = const [],
    this.isOfflineData = false,
  });

  /// Calculates the total current value of the holding.
  /// Falls back to [averagePrice] if [currentPrice] is unavailable.
  double get totalValue => amount * (currentPrice ?? averagePrice);

  /// Calculates the absolute Unrealized Profit/Loss.
  double get profitLoss => totalValue - (amount * averagePrice);

  /// Returns a display label for the unit of measure based on [AssetType].
  String get unitLabel {
    switch (type) {
      case AssetType.metal:
      case AssetType.commodity:
        return 'Gram'; // Placeholder logic
      case AssetType.stock:
        return 'Lot';
      case AssetType.crypto:
      default:
        return symbol.toUpperCase();
    }
  }

  /// Creates a copy of this instance with the given fields replaced with new values.
  InvestmentAsset copyWith({
    String? id,
    String? symbol,
    String? name,
    double? amount,
    double? averagePrice,
    String? imageUrl,
    double? currentPrice,
    double? priceChange24h,
    AssetType? type,
    double? currencyRate,
    String? sector,
    double? riskScore,
    double? volatility,
    List<double>? lastSevenDaysPrices,
    bool? isOfflineData,
  }) {
    return InvestmentAsset(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      averagePrice: averagePrice ?? this.averagePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      currentPrice: currentPrice ?? this.currentPrice,
      priceChange24h: priceChange24h ?? this.priceChange24h,
      type: type ?? this.type,
      currencyRate: currencyRate ?? this.currencyRate,
      sector: sector ?? this.sector,
      riskScore: riskScore ?? this.riskScore,
      volatility: volatility ?? this.volatility,
      lastSevenDaysPrices: lastSevenDaysPrices ?? this.lastSevenDaysPrices,
      isOfflineData: isOfflineData ?? this.isOfflineData,
    );
  }

  @override
  List<Object?> get props => [
        id,
        symbol,
        name,
        amount,
        averagePrice,
        imageUrl,
        currentPrice,
        priceChange24h,
        type,
        currencyRate,
        sector,
        riskScore,
        volatility,
        lastSevenDaysPrices,
        isOfflineData,
      ];
}
