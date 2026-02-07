import 'package:equatable/equatable.dart';

class AssetDetail extends Equatable {
  final String id;
  final String symbol;
  final String name;
  final String? imageUrl;
  final double currentPrice;
  final double priceChange24h;
  final double marketCap;
  final double totalVolume;
  final double ath;
  final List<List<double>> prices; // [timestamp, price]
  final double currencyRate;

  const AssetDetail({
    required this.id,
    required this.symbol,
    required this.name,
    this.imageUrl,
    required this.currentPrice,
    required this.priceChange24h,
    required this.marketCap,
    required this.totalVolume,
    required this.ath,
    required this.prices,
    this.currencyRate = 1.0, // Added for UI conversion
  });

  @override
  List<Object?> get props => [
        id,
        symbol,
        name,
        imageUrl,
        currentPrice,
        priceChange24h,
        marketCap,
        totalVolume,
        ath,
        prices,
        currencyRate,
      ];
}
