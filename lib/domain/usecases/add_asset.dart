import '../entities/investment_asset.dart';
import '../repositories/investment_repository.dart';

class AddAsset {
  final InvestmentRepository repository;

  AddAsset(this.repository);

  Future<void> execute(InvestmentAsset asset) {
    return repository.addAsset(asset);
  }
}
