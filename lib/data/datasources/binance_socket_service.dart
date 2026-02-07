import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for handling real-time price updates via Binance WebSocket API.
///
/// Connects to the Binance Stream to receive live trade data for tracked assets.
/// Updates are broadcast via a Stream for BLoCs or UI components to consume.
class BinanceWebSocketService {
  WebSocketChannel? _channel;

  /// Broadcast stream controller to allow multiple listeners (allocations, charts, etc.)
  final StreamController<Map<String, double>> _priceController =
      StreamController.broadcast();

  /// Stream of price updates.
  ///
  /// Emits a Map where key is the symbol (e.g. "BTC") and value is the current price.
  Stream<Map<String, double>> get priceStream => _priceController.stream;

  /// Connects to Binance WebSocket for a list of symbols.
  ///
  /// [symbols] should be a list of ticker symbols (e.g. ["BTC", "ETH", "SOL"]).
  /// The service converts them to the required lowercase 'usdt' format.
  void connect(List<String> symbols) {
    if (symbols.isEmpty) return;

    // Binance format: lowercase symbol + 'usdt' (e.g. btcusdt, ethusdt)
    // Stream name: <symbol>@trade
    // We combine multiple streams into a single connection string.
    final streams =
        symbols.map((s) => '${s.toLowerCase()}usdt@trade').join('/');
    final url = 'wss://stream.binance.com:9443/stream?streams=$streams';

    print('Connecting to Binance WS: $url');
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data['data'] != null) {
          final trade = data['data'];

          // 's' is the symbol (e.g "BTCUSDT"), we strip 'USDT' to match internal IDs
          final symbol = trade['s'].toString().replaceFirst('USDT', '');

          // 'p' is the price string
          final price = double.tryParse(trade['p']) ?? 0.0;

          if (price > 0) {
            _priceController.add({symbol: price});
          }
        }
      },
      onError: (error) {
        print('Binance WS Error: $error');
        // TODO: Implement reconnection strategy (exponential backoff)
      },
      onDone: () {
        print('Binance WS Closed');
      },
    );
  }

  /// Closes the WebSocket connection and the stream controller.
  ///
  /// Should be called when the app is terminated or specific features are disposed.
  void disconnect() {
    _channel?.sink.close();
    _priceController.close();
  }
}
