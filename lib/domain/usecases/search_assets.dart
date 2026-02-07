import '../entities/investment_asset.dart';
import '../repositories/investment_repository.dart';

/// Use Case for searching assets.
///
/// Executes a search query against the repository to find assets matching the name or symbol.
class SearchAssets {
  final InvestmentRepository repository;

  SearchAssets(this.repository);

  /// Executes the search.
  ///
  /// [query] - The search string (e.g., "Bit", "AAPL").
  /// Returns a list of matching [InvestmentAsset]s.
  Future<List<InvestmentAsset>> execute(String query) {
    return repository.searchAssets(query);
  }
}
