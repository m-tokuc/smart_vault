import 'package:equatable/equatable.dart';
import '../../domain/entities/investment_asset.dart'; // Added for AssetType

/// Base class for all portfolio-related events.
abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

/// Event to trigger the initial load of portfolio data.
class LoadPortfolio extends PortfolioEvent {}

/// Event to force a refresh of asset prices (e.g. pull-to-refresh).
class RefreshPrices extends PortfolioEvent {}

/// Internal event fired when new real-time prices are received from the WebSocket.
class UpdateRealTimePrice extends PortfolioEvent {
  final Map<String, double> prices;

  const UpdateRealTimePrice(this.prices);

  @override
  List<Object?> get props => [prices];
}

/// Event to add a new asset to the portfolio.
class AddAssetEvent extends PortfolioEvent {
  final String id;
  final String symbol;
  final String name;
  final double amount;
  final double price;
  final String? imageUrl;
  final AssetType type;

  const AddAssetEvent({
    required this.id,
    required this.symbol,
    required this.name,
    required this.amount,
    required this.price,
    this.imageUrl,
    this.type = AssetType.crypto,
  });

  @override
  List<Object?> get props => [id, symbol, name, amount, price, imageUrl, type];
}

/// Event to remove an asset from the portfolio.
class DeleteAssetEvent extends PortfolioEvent {
  final String id;

  const DeleteAssetEvent(this.id);

  @override
  List<Object?> get props => [id];
}
