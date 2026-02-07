import 'package:dio/dio.dart';
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';
import '../../domain/entities/asset_detail.dart';
import '../../domain/entities/investment_asset.dart';
import '../models/investment_asset_model.dart';
import 'asset_remote_datasource.dart';

abstract class AssetRemoteDataSource {
  Future<AssetDetail> getAssetDetail(String id, AssetType type,
      {String period = '1D'});
  Future<List<InvestmentAssetModel>> searchAssets(String query);
  Future<List<InvestmentAssetModel>> getPopularAssets();
  Future<Map<String, double>> getCurrentPrices(
      List<InvestmentAsset>
          assets); // Changed signature to pass full objects for routing
}

class AssetRemoteDataSourceImpl implements AssetRemoteDataSource {
  final Dio dio;

  AssetRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, double>> getCurrentPrices(
      List<InvestmentAsset> assets) async {
    final Map<String, double> prices = {};

    // Group by source to optimize calls
    final cryptoIds = assets
        .where((a) => a.type == AssetType.crypto)
        .map((a) => a.id)
        .toList();
    final yahooIds = assets
        .where((a) => a.type != AssetType.crypto)
        .map((a) => a.id)
        .toList();

    // 1. Fetch Crypto (Batch if possible, currently using detail loop for simplicity but could be optimized)
    // CoinGecko supports batch price: /simple/price?ids=bitcoin,ethereum...
    if (cryptoIds.isNotEmpty) {
      try {
        final response = await dio.get(
          'https://api.coingecko.com/api/v3/simple/price',
          queryParameters: {
            'ids': cryptoIds.join(','),
            'vs_currencies': 'usd',
          },
        );
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          data.forEach((key, value) {
            prices[key] = (value['usd'] as num).toDouble();
          });
        }
      } catch (e) {
        print('Crypto Batch Fetch Error: $e');
      }
    }

    // 2. Fetch Yahoo (Yahoo Finance reader doesn't support batch easily, loop for now or find batch equivalent)
    // The library usually does single tickers. Parallelize.
    if (yahooIds.isNotEmpty) {
      final futures = yahooIds.map((id) async {
        try {
          final detail = await _getStockDetail(id, '1D');
          return MapEntry(id, detail.currentPrice);
        } catch (_) {
          return MapEntry(id, 0.0);
        }
      });
      final results = await Future.wait(futures);
      for (var entry in results) {
        if (entry.value > 0) prices[entry.key] = entry.value;
      }
    }

    return prices;
  }

  @override
  Future<AssetDetail> getAssetDetail(String id, AssetType type,
      {String period = '1D'}) async {
    // SMART ROUTER LOGIC
    try {
      if (type == AssetType.crypto) {
        return await _getCryptoDetail(id, period);
      } else {
        return await _getStockDetail(id, period);
      }
    } catch (e) {
      print('Smart Router Error for $id ($type): $e');
      throw Exception('Failed to fetch data');
    }
  }

  Future<AssetDetail> _getCryptoDetail(String id, String period) async {
    int days;
    if (period == '1D')
      days = 1;
    else if (period == '1W')
      days = 7;
    else if (period == '1M')
      days = 30;
    else
      days = 365;

    final response = await dio.get(
      'https://api.coingecko.com/api/v3/coins/$id',
      queryParameters: {
        'localization': false,
        'tickers': false,
        'market_data': true,
        'community_data': false,
        'developer_data': false,
        'sparkline': false,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final marketData = data['market_data'];

      List<List<double>> pricesList = [];
      try {
        final chartResponse = await dio.get(
          'https://api.coingecko.com/api/v3/coins/$id/market_chart',
          queryParameters: {
            'vs_currency': 'usd',
            'days': days.toString(),
          },
        );
        if (chartResponse.statusCode == 200) {
          final chartData = chartResponse.data;
          pricesList = (chartData['prices'] as List).map((e) {
            return (e as List).map((val) => (val as num).toDouble()).toList();
          }).toList();
        }
      } catch (_) {}

      return AssetDetail(
        id: data['id'],
        symbol: data['symbol'],
        name: data['name'],
        currentPrice: (marketData['current_price']['usd'] as num).toDouble(),
        marketCap: (marketData['market_cap']['usd'] as num).toDouble(),
        totalVolume: (marketData['total_volume']['usd'] as num).toDouble(),
        priceChange24h:
            (marketData['price_change_percentage_24h'] as num?)?.toDouble() ??
                0.0,
        prices: pricesList,
        ath: (marketData['ath']['usd'] as num).toDouble(),
        imageUrl: data['image']?['large'],
        currencyRate: 1.0,
      );
    }
    throw Exception('CoinGecko Error');
  }

  Future<AssetDetail> _getStockDetail(String ticker, String period) async {
    final yahooReader = YahooFinanceService();

    final now = DateTime.now();
    DateTime startDate = now.subtract(const Duration(days: 1));
    if (period == '1W') startDate = now.subtract(const Duration(days: 7));
    if (period == '1M') startDate = now.subtract(const Duration(days: 30));
    if (period == '1Y') startDate = now.subtract(const Duration(days: 365));

    // This call might throw if symbol not found
    List<YahooFinanceCandleData> candles = await yahooReader.getTickerData(
      ticker,
      useCache: true,
    );

    final filtered = candles.where((c) => c.date.isAfter(startDate)).toList();
    var displayCandles = filtered;
    if (displayCandles.isEmpty && candles.isNotEmpty) {
      // Fallback to last available data if no recent data (e.g. weekend)
      displayCandles = candles.take(30).toList();
    }

    if (displayCandles.isEmpty) {
      throw Exception('No stock data found');
    }

    displayCandles.sort((a, b) => a.date.compareTo(b.date));

    final latest = displayCandles.last;
    double current = latest.close;
    double previous = displayCandles.first.close;

    // Calculate change
    double change = 0.0;
    if (previous != 0) {
      change = ((current - previous) / previous) * 100;
    }

    final pricesList = displayCandles.map((c) {
      return [c.date.millisecondsSinceEpoch.toDouble(), c.close];
    }).toList();

    return AssetDetail(
      id: ticker,
      symbol: ticker
          .split('=')[0], // Extract symbol for display if it has = (like GC=F)
      name: ticker,
      currentPrice: current,
      marketCap: 0,
      totalVolume: latest.volume.toDouble(),
      priceChange24h: change,
      prices: pricesList,
      ath: 0.0,
      imageUrl: null,
    );
  }

  @override
  Future<List<InvestmentAssetModel>> searchAssets(String query) async {
    // MEGA SEARCH: Parallel Execution

    // 1. Google Finance / Yahoo Finance (Stocks/Commodities) - Simulated for now or mapped
    // Since we don't have a direct "Search API" for Yahoo in the package easily,
    // we can use a known list or try to map user input if it looks like a ticker.
    // Ideally we would use an autocomplete API.
    // For this pro level, let's include a robust local list of top 50 global assets
    // AND try to hit CoinGecko Search.

    final lowerQuery = query.toLowerCase();
    final List<InvestmentAssetModel> results = [];

    // A. Manual Top Stocks/Metals Database (Mini)
    final proDatabase = [
      InvestmentAssetModel(
          id: 'AAPL',
          symbol: 'AAPL',
          name: 'Apple Inc.',
          type: AssetType.stock,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Technology'),
      InvestmentAssetModel(
          id: 'MSFT',
          symbol: 'MSFT',
          name: 'Microsoft Corp',
          type: AssetType.stock,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Technology'),
      InvestmentAssetModel(
          id: 'GOOGL',
          symbol: 'GOOGL',
          name: 'Alphabet Inc.',
          type: AssetType.stock,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Technology'),
      InvestmentAssetModel(
          id: 'TSLA',
          symbol: 'TSLA',
          name: 'Tesla Inc.',
          type: AssetType.stock,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Automotive'),
      InvestmentAssetModel(
          id: 'AMZN',
          symbol: 'AMZN',
          name: 'Amazon.com',
          type: AssetType.stock,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Retail'),
      InvestmentAssetModel(
          id: 'NVDA',
          symbol: 'NVDA',
          name: 'NVIDIA Corp',
          type: AssetType.stock,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Technology'),
      InvestmentAssetModel(
          id: 'GC=F',
          symbol: 'GC=F',
          name: 'Gold Futures',
          type: AssetType.metal,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Commodity'),
      InvestmentAssetModel(
          id: 'SI=F',
          symbol: 'SI=F',
          name: 'Silver Futures',
          type: AssetType.metal,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Commodity'),
      InvestmentAssetModel(
          id: 'EURUSD=X',
          symbol: 'EURUSD',
          name: 'EUR/USD',
          type: AssetType.forex,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Currency'),
      InvestmentAssetModel(
          id: 'TRY=X',
          symbol: 'USDTRY',
          name: 'USD/TRY',
          type: AssetType.forex,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Currency'),
    ];

    if (query.isNotEmpty) {
      results.addAll(proDatabase.where((s) =>
          s.symbol.toLowerCase().contains(lowerQuery) ||
          s.name.toLowerCase().contains(lowerQuery)));
    }

    // B. CoinGecko Search (Crypto)
    try {
      final response = await dio.get(
        'https://api.coingecko.com/api/v3/search',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200) {
        final coins = response.data['coins'] as List;
        final cryptoResults = coins.take(10).map((json) {
          // Limit to 10
          return InvestmentAssetModel(
            id: json['id'],
            symbol: json['symbol'],
            name: json['name'],
            imageUrl: json['large'],
            currentPrice: 0,
            type: AssetType.crypto,
            amount: 0,
            averagePrice: 0,
            sector: 'Crypto',
          );
        }).toList();
        results.addAll(cryptoResults);
      }
    } catch (_) {
      print('CoinGecko Search Failed (Offline?)');
    }

    return results;
  }

  @override
  Future<List<InvestmentAssetModel>> getPopularAssets() async {
    return [
      InvestmentAssetModel(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          imageUrl:
              'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
          currentPrice: 0,
          type: AssetType.crypto,
          amount: 0,
          averagePrice: 0,
          sector: 'Crypto'),
      InvestmentAssetModel(
          id: 'ethereum',
          symbol: 'ETH',
          name: 'Ethereum',
          imageUrl:
              'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
          currentPrice: 0,
          type: AssetType.crypto,
          amount: 0,
          averagePrice: 0,
          sector: 'Crypto'),
      InvestmentAssetModel(
          id: 'AAPL',
          symbol: 'AAPL',
          name: 'Apple Inc.',
          type: AssetType.stock,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Technology'),
      InvestmentAssetModel(
          id: 'GC=F',
          symbol: 'GC=F',
          name: 'Gold',
          type: AssetType.metal,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Commodity'),
      InvestmentAssetModel(
          id: 'TRY=X',
          symbol: 'USDTRY',
          name: 'USD/TRY',
          type: AssetType.forex,
          amount: 0,
          averagePrice: 0,
          currentPrice: 0,
          sector: 'Currency'),
    ];
  }
}
