import '../entities/investment_asset.dart';
import '../entities/asset_detail.dart';

abstract class InvestmentRepository {
  Future<List<InvestmentAsset>> getAssets();
  Future<void> addAsset(InvestmentAsset asset);
  Future<void> deleteAsset(String id);
  Future<List<InvestmentAsset>> searchAssets(String query);
  Future<List<InvestmentAsset>> getPopularAssets();
  Future<AssetDetail> getAssetDetail(String id, {String period = '1W'});
}
