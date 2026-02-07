import 'package:smart_vault/data/datasources/asset_remote_datasource.dart';
import 'package:dio/dio.dart';

void main() async {
  print('--- Starting Manual Data Source Test ---');
  final dio = Dio();
  final dataSource = AssetRemoteDataSourceImpl(dio: dio);

  // Test 1: Crypto (Bitcoin)
  try {
    print('1. Testing Crypto (bitcoin)...');
    final btc = await dataSource.getAssetDetail('bitcoin');
    print('SUCCESS: ${btc.name} Price: \$${btc.currentPrice}');
  } catch (e) {
    print('FAILURE: Crypto test failed: $e');
  }

  // Test 2: Stock (AAPL) - via Yahoo
  print('\n2. Testing Stock (AAPL)...');
  try {
    final appl = await dataSource.getAssetDetail('AAPL');
    print('SUCCESS: ${appl.name} Price: \$${appl.currentPrice}');
  } catch (e) {
    print('FAILURE: Stock test failed: $e');
  }

  // Test 3: Circuit Breaker (Invalid ID)
  print('\n3. Testing Circuit Breaker (INVALID_ASSET_ID)...');
  try {
    final invalid = await dataSource.getAssetDetail('INVALID_ASSET_ID_999');
    if (invalid.currentPrice == 0.0 && invalid.name == 'INVALID_ASSET_ID_999') {
      print('SUCCESS: Circuit Breaker worked. Returned Safe Object.');
    } else {
      print(
          'FAILURE: Returned object but not safe fallback: ${invalid.name} ${invalid.currentPrice}');
    }
  } catch (e) {
    print('FAILURE: Circuit Breaker FAILED. Exception thrown: $e');
  }

  // Test 4: Search (Apple)
  print('\n4. Testing Search (Apple)...');
  try {
    final results = await dataSource.searchAssets('Apple');
    print('Found ${results.length} results.');
    final hasStock =
        results.any((r) => r.symbol == 'AAPL' && r.type == 'stock');
    final hasCrypto = results.any((r) => r.type == 'crypto');

    if (hasStock)
      print('SUCCESS: Found Apple Stock.');
    else
      print('FAILURE: Apple Stock NOT found in search.');

    if (hasCrypto)
      print('SUCCESS: Found Crypto results.');
    else
      print('FAILURE: Crypto results NOT found.');
  } catch (e) {
    print('FAILURE: Search test failed: $e');
  }

  // Test 5: getCurrentPrices
  print('\n5. Testing getCurrentPrices([bitcoin, AAPL, INVALID])...');
  try {
    final prices =
        await dataSource.getCurrentPrices(['bitcoin', 'AAPL', 'INVALID_999']);
    print('Prices: $prices');
    if (prices.containsKey('bitcoin') &&
        prices.containsKey('AAPL') &&
        prices['INVALID_999'] == 0.0) {
      print('SUCCESS: getCurrentPrices returned expected map.');
    } else {
      print('FAILURE: getCurrentPrices map incorrect.');
    }
  } catch (e) {
    print('FAILURE: getCurrentPrices threw exception: $e');
  }

  print('\n--- Test Finished ---');
}
