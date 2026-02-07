import '../repositories/investment_repository.dart';

class DeleteAsset {
  final InvestmentRepository repository;

  DeleteAsset(this.repository);

  Future<void> execute(String id) {
    return repository.deleteAsset(id);
  }
}
