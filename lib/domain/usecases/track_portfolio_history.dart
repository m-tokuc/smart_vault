import '../../data/datasources/portfolio_history_local_datasource.dart';

class TrackPortfolioHistory {
  final PortfolioHistoryLocalDataSource dataSource;

  TrackPortfolioHistory(this.dataSource);

  Future<void> execute(double totalBalance) async {
    // Logic: Just save it. The data source handles keying by date.
    // If we call this multiple times a day, it overwrites with the latest value for "today",
    // which is usually desired behavior (EndOfDay value).
    if (totalBalance > 0) {
      await dataSource.saveSnapshot(totalBalance);
    }
  }
}
