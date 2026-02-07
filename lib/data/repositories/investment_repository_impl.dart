import '../../domain/entities/investment_asset.dart';
import '../../domain/repositories/investment_repository.dart';
import '../datasources/asset_local_datasource.dart';
import '../datasources/asset_remote_datasource.dart';
import '../../domain/entities/asset_detail.dart';
import '../models/investment_asset_model.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  final AssetLocalDataSource localDataSource;
  final AssetRemoteDataSource remoteDataSource;

  InvestmentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<InvestmentAsset>> getAssets() async {
    // 1. Fetch Local Assets (Single Source of Truth for "My Assets")
    final localAssets = await localDataSource.getAssets();

    if (localAssets.isEmpty) {
      return [];
    }

    // 2. Try Fetch Remote Prices
    try {
      // Pass full objects for Smart Routing (Crypto vs Stock)
      final prices = await remoteDataSource.getCurrentPrices(localAssets);

      final updatedAssets = <InvestmentAsset>[];

      for (var model in localAssets) {
        final newPrice = prices[model.id] ?? model.currentPrice;

        // Create Updated Entity
        final updatedAsset = model.copyWith(
          currentPrice: newPrice,
          isOfflineData: false, // Success!
        );

        updatedAssets.add(updatedAsset);

        // 3. Cache the Fresh Data (Silent Persistence)
        // We save the Updated Model back to Hive so next time we have freshest offline data
        await localDataSource
            .saveAsset(InvestmentAssetModel.fromEntity(updatedAsset));
      }

      return updatedAssets;
    } catch (e) {
      print('Network Error/API Fail: $e. Using Cache.');
      // 4. Fallback to Local Data (Offline Mode)
      // Return local assets but flag them as offline
      return localAssets.map((e) => e.copyWith(isOfflineData: true)).toList();
    }
  }

  @override
  Future<void> addAsset(InvestmentAsset asset) async {
    final model = InvestmentAssetModel.fromEntity(asset);
    await localDataSource.saveAsset(model);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await localDataSource.deleteAsset(id);
  }

  @override
  Future<List<InvestmentAsset>> searchAssets(String query) async {
    try {
      final models = await remoteDataSource.searchAssets(query);
      return models.map((e) => e.toEntity()).toList();
    } catch (_) {
      // If search fails completely (no net), return empty or maybe local matches?
      // For now empty list is safer than crashing.
      return [];
    }
  }

  @override
  Future<List<InvestmentAsset>> getPopularAssets() async {
    try {
      final models = await remoteDataSource.getPopularAssets();
      return models.map((e) => e.toEntity()).toList();
    } catch (_) {
      // Return basic list if network fails, preventing "Popular" section crash
      return [];
    }
  }

  @override
  Future<AssetDetail> getAssetDetail(String id, {String period = '1W'}) async {
    // We need to know the Type for the router.
    // OPTIMIZATION: Check local storage first to see if we know the type?
    // Or just try both?
    // Challenge: getAssetDetail in Domain doesn't require Type.
    // Solution: We can try to infer or we should update Domain to pass Type.
    // BUT since we can't easily change User's call site in pages without context...
    // Let's Peek at Local Data first!

    AssetType inferredType = AssetType.crypto; // Default
    try {
      final localAssets = await localDataSource.getAssets();
      final match = localAssets.firstWhere((a) => a.id == id);
      inferredType = match.type;
    } catch (_) {
      // Not in portfolio, try heuristic or try-error
      if (id.length <= 5 && id == id.toUpperCase())
        inferredType = AssetType.stock;
    }

    try {
      return await remoteDataSource.getAssetDetail(id, inferredType,
          period: period);
    } catch (e) {
      // Return a "Cached" version if we had charts cached?
      // Currently we don't cache full AssetDetail/Charts in Hive, only basic prices.
      // So we throw or return chartless detail.

      // Fallback: Construct detail from Portfolio data if exists
      final localAssets = await localDataSource.getAssets();
      try {
        final match = localAssets.firstWhere((a) => a.id == id);
        return AssetDetail(
          id: match.id,
          symbol: match.symbol,
          name: match.name,
          currentPrice: match.currentPrice ?? 0,
          marketCap: 0,
          totalVolume: 0,
          priceChange24h: 0,
          prices: [], // No charts
          ath: 0,
          imageUrl: match.imageUrl,
          currencyRate: 1.0,
        );
      } catch (_) {
        throw e; // RETHROW if we really know nothing about this asset
      }
    }
  }
}
