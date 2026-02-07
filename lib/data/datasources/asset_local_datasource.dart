import 'package:hive/hive.dart';
import '../models/investment_asset_model.dart';

abstract class AssetLocalDataSource {
  Future<List<InvestmentAssetModel>> getAssets();
  Future<void> saveAsset(InvestmentAssetModel asset);
  Future<void> deleteAsset(String id);
}

class AssetLocalDataSourceImpl implements AssetLocalDataSource {
  final Box<InvestmentAssetModel> assetBox;

  AssetLocalDataSourceImpl(this.assetBox);

  @override
  Future<List<InvestmentAssetModel>> getAssets() async {
    return assetBox.values.toList();
  }

  @override
  Future<void> saveAsset(InvestmentAssetModel asset) async {
    await assetBox.put(asset.id, asset);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await assetBox.delete(id);
  }
}
