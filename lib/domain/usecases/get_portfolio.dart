import '../entities/investment_asset.dart';
import '../repositories/investment_repository.dart';

class GetPortfolio {
  final InvestmentRepository repository;

  GetPortfolio(this.repository);

  Future<List<InvestmentAsset>> execute() {
    return repository.getAssets();
  }
}
