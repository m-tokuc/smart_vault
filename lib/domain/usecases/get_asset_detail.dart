import '../entities/asset_detail.dart';
import '../repositories/investment_repository.dart';

class GetAssetDetail {
  final InvestmentRepository repository;

  GetAssetDetail(this.repository);

  Future<AssetDetail> execute(String id, {String period = '1W'}) {
    return repository.getAssetDetail(id, period: period);
  }
}
