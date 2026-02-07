import 'package:hive/hive.dart';

class PortfolioHistoryLocalDataSource {
  static const String boxName = 'portfolio_history';
  final Box box;

  PortfolioHistoryLocalDataSource(this.box);

  // Key: "yyyy-MM-dd" -> Value: double (Total Balance)
  Future<void> saveSnapshot(double totalBalance) async {
    final now = DateTime.now();
    final key =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    await box.put(key, totalBalance);
  }

  Map<String, double> getHistory() {
    final Map<String, double> history = {};
    for (var key in box.keys) {
      final value = box.get(key);
      if (value is double) {
        history[key.toString()] = value;
      } else if (value is num) {
        history[key.toString()] = value.toDouble();
      }
    }
    // Sort logic handled by caller or chart usually, but Map is unordered.
    return history;
  }
}
