import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/investment_asset.dart';
import '../../domain/usecases/add_asset.dart';
import '../../domain/usecases/delete_asset.dart';
import '../../domain/usecases/get_portfolio.dart';
import '../../domain/usecases/calculate_portfolio_statistics.dart';
import '../../domain/usecases/track_portfolio_history.dart';
import '../../data/datasources/binance_socket_service.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

/// BLoC for managing the Portfolio state.
///
/// Handles fetching portfolio data, adding/removing assets, and real-time price updates.
/// It acts as the bridge between the UI (Dashboard) and the Domain/Data layers.
class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final GetPortfolio getPortfolio;
  final AddAsset addAsset;
  final DeleteAsset deleteAsset;
  final CalculatePortfolioStatistics calculateStats;
  final TrackPortfolioHistory trackHistory;
  final BinanceWebSocketService binanceService;
  StreamSubscription? _priceSubscription;

  PortfolioBloc({
    required this.getPortfolio,
    required this.addAsset,
    required this.deleteAsset,
    required this.binanceService,
    required this.calculateStats,
    required this.trackHistory,
  }) : super(PortfolioLoading()) {
    on<LoadPortfolio>(_onLoadPortfolio);
    on<RefreshPrices>(_onLoadPortfolio);
    on<AddAssetEvent>(_onAddAsset);
    on<DeleteAssetEvent>(_onDeleteAsset);
    on<UpdateRealTimePrice>(_onUpdateRealTimePrice);
  }

  @override
  Future<void> close() {
    _priceSubscription?.cancel();
    binanceService.disconnect();
    return super.close();
  }

  /// Loads the portfolio assets and initializes real-time updates.
  Future<void> _onLoadPortfolio(
    PortfolioEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) {
      emit(PortfolioLoading());
    }

    try {
      final assets = await getPortfolio.execute();

      // Calculate Stats
      // NOTE: Current currency rate defaults to 1.0 (USD).
      // Future improvement: Listen to SettingsBloc for rate changes.
      final stats = calculateStats.execute(assets: assets, currencyRate: 1.0);

      emit(PortfolioLoaded(
        assets: assets,
        stats: stats,
        lastUpdated: DateTime.now(),
      ));

      // Track History (Snapshot for Analytics)
      trackHistory.execute(stats.totalBalance);

      // Connect to WebSocket for live pricing
      _setupSockets(assets);
    } catch (e) {
      emit(PortfolioError(e.toString()));
    }
  }

  /// Handles real-time price updates from the WebSocket service.
  ///
  /// Updates the `currentPrice` of matching assets and recalculates the portfolio stats.
  Future<void> _onUpdateRealTimePrice(
    UpdateRealTimePrice event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is PortfolioLoaded) {
      final currentState = state as PortfolioLoaded;

      // 1. Update Assets with new prices
      final updatedAssets = currentState.assets.map((asset) {
        final symbolUpper = asset.symbol.toUpperCase();
        double? newPrice;

        // Check if we have a price update for this asset
        event.prices.forEach((key, value) {
          if (key.toUpperCase() == symbolUpper) {
            newPrice = value;
          }
        });

        if (newPrice != null) {
          return asset.copyWith(currentPrice: newPrice);
        }
        return asset;
      }).toList();

      // 2. Recalculate Stats based on new prices
      final stats =
          calculateStats.execute(assets: updatedAssets, currencyRate: 1.0);

      emit(PortfolioLoaded(
        assets: updatedAssets,
        stats: stats,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Adds a new asset to the portfolio and reloads the state.
  Future<void> _onAddAsset(
    AddAssetEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      final newAsset = InvestmentAsset(
        id: event.id,
        symbol: event.symbol,
        name: event.name,
        type: event.type,
        amount: event.amount,
        averagePrice: event.price,
        imageUrl: event.imageUrl,
        currentPrice: event.price,
      );

      await addAsset.execute(newAsset);
      add(LoadPortfolio()); // Reload to ensure sync and socket subscription
    } catch (e) {
      emit(PortfolioError('Failed to add asset: $e'));
    }
  }

  /// Deletes an asset from the portfolio and reloads the state.
  Future<void> _onDeleteAsset(
    DeleteAssetEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      await deleteAsset.execute(event.id);
      add(LoadPortfolio());
    } catch (e) {
      emit(PortfolioError('Failed to delete asset: $e'));
    }
  }

  /// Sets up the WebSocket connection for the current list of assets.
  ///
  /// Filters for crypto assets (since Binance only supports crypto) and connects.
  void _setupSockets(List<InvestmentAsset> assets) {
    List<String> cryptoSymbols = [];
    for (var asset in assets) {
      if (asset.type == AssetType.crypto) {
        cryptoSymbols.add(asset.symbol);
      }
    }

    _priceSubscription?.cancel();
    binanceService.disconnect();

    if (cryptoSymbols.isNotEmpty) {
      binanceService.connect(cryptoSymbols);
      _priceSubscription = binanceService.priceStream.listen((prices) {
        add(UpdateRealTimePrice(prices));
      });
    }
  }
}
