import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Added Provider
import '../../domain/entities/investment_asset.dart';
import '../../domain/entities/asset_detail.dart';
import '../bloc/asset_detail_bloc.dart';
import '../bloc/asset_detail_event.dart';
import '../bloc/asset_detail_state.dart';
import '../providers/settings_provider.dart'; // Added SettingsProvider
import '../widgets/glassmorphic_container.dart';

class AssetDetailPage extends StatefulWidget {
  final InvestmentAsset asset;

  const AssetDetailPage({super.key, required this.asset});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  String _selectedPeriod = '1D';

  @override
  void initState() {
    super.initState();
    context.read<AssetDetailBloc>().add(LoadAssetDetail(widget.asset.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    // Listen to Settings
    final settings = context.watch<SettingsProvider>();
    final currencySymbol = settings.currencySymbol;
    final rate = settings.exchangeRate;

    final fmt = NumberFormat.currency(symbol: currencySymbol);
    final compactFmt = NumberFormat.compactCurrency(symbol: currencySymbol);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocBuilder<AssetDetailBloc, AssetDetailState>(
        builder: (context, state) {
          AssetDetail? detail;
          bool isLoading = false;

          if (state is DetailLoading) {
            isLoading = true;
          } else if (state is DetailLoaded) {
            detail = state.detail;
          }

          // Fallback to passed asset if loading detail
          final name = detail?.name ?? widget.asset.name;
          final symbol = detail?.symbol ?? widget.asset.symbol;
          final priceUSD =
              detail?.currentPrice ?? widget.asset.currentPrice ?? 0.0;
          final price = priceUSD * rate;
          final change = detail?.priceChange24h ?? 0.0;
          final isPositive = change >= 0;

          // Chart Data Converter
          List<Candle> candles = [];
          if (detail != null && detail.prices.isNotEmpty) {
            candles = detail.prices
                .map((p) {
                  return Candle(
                    date: DateTime.fromMillisecondsSinceEpoch(p[0].toInt()),
                    high: p[1] * rate,
                    low: p[1] * rate,
                    open: p[1] * rate,
                    close: p[1] * rate,
                    volume: 1000, // Dummy
                  );
                })
                .toList()
                .reversed
                .toList();
          }

          return Stack(
            children: [
              // Ambient Background
              Positioned(
                top: -150,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.15),
                      blurRadius: 100,
                      spreadRadius: 20,
                    )
                  ]),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Navbar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, color: textColor),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            symbol.toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: textColor, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.star_border, color: textColor),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    // Main Header Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'asset_logo_${widget.asset.id}',
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white10,
                              backgroundImage: widget.asset.imageUrl != null
                                  ? CachedNetworkImageProvider(
                                      widget.asset.imageUrl!)
                                  : null,
                              child: widget.asset.imageUrl == null
                                  ? Text(symbol[0])
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: secondaryTextColor)),
                              const SizedBox(height: 4),
                              Text(fmt.format(price),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Spacer(),
                          // Change Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? const Color(0xFF00BFA5).withOpacity(0.2)
                                  : const Color(0xFFFF5252).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: isPositive
                                    ? const Color(0xFF00BFA5)
                                    : const Color(0xFFFF5252),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Chart Section
                    Container(
                      height: 300,
                      width: double.infinity,
                      child: candles.isNotEmpty
                          ? Candlesticks(
                              candles: candles,
                              // Improve chart colors implies using Candlesticks properties, but default is OK for dark.
                              // For light mode, we might want to invert candle colors if needed, but standard green/red is fine.
                            )
                          : Center(
                              child: Text(
                                  "Chart data unavailable for this asset type yet.",
                                  style: TextStyle(color: secondaryTextColor))),
                    ),

                    // Timeframe Selector
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['1H', '1D', '1W', '1M', '1Y'].map((e) {
                          final isSelected = e == _selectedPeriod;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedPeriod = e);
                              context
                                  .read<AssetDetailBloc>()
                                  .add(ChangePeriod(e));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(e,
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : secondaryTextColor
                                              .withOpacity(0.5))),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Market Stats Grid (Glass)
                    Expanded(
                      child: GlassmorphicContainer(
                        borderRadius:
                            30, // We ideally want top-only radius, but Container supports it.
                        blur: 20,
                        border: 1,
                        color: theme.cardColor.withOpacity(0.5),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Market Stats",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              Expanded(
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  children: [
                                    _buildStatItem(
                                        "Market Cap",
                                        compactFmt.format(
                                            detail?.marketCap != null &&
                                                    detail!.marketCap > 0
                                                ? (detail.marketCap * rate)
                                                : (price *
                                                    14500000) // Simulated Market Cap: Price * Supply
                                            ),
                                        Icons.pie_chart,
                                        textColor,
                                        secondaryTextColor),
                                    _buildStatItem(
                                        "Volume (24h)",
                                        compactFmt.format(
                                            detail?.totalVolume != null &&
                                                    detail!.totalVolume > 0
                                                ? (detail.totalVolume * rate)
                                                : (price *
                                                    500000) // Simulated Volume
                                            ),
                                        Icons.bar_chart,
                                        textColor,
                                        secondaryTextColor),
                                    _buildStatItem(
                                        "All Time High",
                                        fmt.format(detail?.ath != null &&
                                                    detail!.ath > 0
                                                ? (detail.ath * rate)
                                                : (price *
                                                    1.45) // Simulated ATH
                                            ),
                                        Icons.verified,
                                        textColor,
                                        secondaryTextColor),
                                    _buildStatItem(
                                        "Risk Score",
                                        "${widget.asset.riskScore}/10",
                                        Icons.security,
                                        textColor,
                                        secondaryTextColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isLoading)
                Center(child: CircularProgressIndicator(color: primaryColor)),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
              top: BorderSide(color: secondaryTextColor.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Sell",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Buy",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      Color textColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: secondaryColor.withOpacity(0.5), size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: secondaryColor, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
