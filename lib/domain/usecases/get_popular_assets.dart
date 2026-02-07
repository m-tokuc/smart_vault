import '../entities/investment_asset.dart';
import '../repositories/investment_repository.dart';

class GetPopularAssets {
  final InvestmentRepository repository;

  GetPopularAssets(this.repository);

  Future<List<InvestmentAsset>> execute() {
    return repository.getPopularAssets();
  }
}
