import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../core/utils/localization_utils.dart';
import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_event.dart';
import '../bloc/portfolio_state.dart';
import '../providers/settings_provider.dart'; // Import SettingsProvider
import '../widgets/glassmorphic_container.dart';
import '../widgets/sparkline_widget.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/portfolio_pie_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// The main dashboard of the SmartVault application.
///
/// Displays the user's Total Balance, Profit/Loss, and a list of Assets.
/// Features a Glassmorphic design, sticky headers, and real-time updates via [PortfolioBloc].
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Trigger initial data load
    context.read<PortfolioBloc>().add(LoadPortfolio());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    // Listen to Settings for currency conversion
    final settings = context.watch<SettingsProvider>();
    final currencySymbol = settings.currencySymbol;
    final rate = settings.exchangeRate;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // --- Ambient Background Effect ---
          // Creates a glowing orb effect in the top-right corner.
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),

          SafeArea(
            child: BlocBuilder<PortfolioBloc, PortfolioState>(
              builder: (context, state) {
                if (state is PortfolioLoading) {
                  return _buildSkeletonLoader();
                } else if (state is PortfolioError) {
                  return Center(
                      child: Text(state.message,
                          style: TextStyle(color: theme.colorScheme.error)));
                } else if (state is PortfolioLoaded) {
                  return _buildDashboardContent(
                      context, state, settings, theme);
                }
                return Container();
              },
            ),
          ),
        ],
      ),
      // --- AI Advisor Chat Button ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/advisor_chat');
        },
      ),
    );
  }

  /// Builds the Skeleton Loading UI state.
  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 150, height: 32),
              SkeletonLoader(width: 40, height: 40),
            ],
          ),
          const SizedBox(height: 20),
          // Balance Card Skeleton
          SkeletonLoader(width: double.infinity, height: 180, borderRadius: 20),
          const SizedBox(height: 30),
          // List Header Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 100, height: 24),
              SkeletonLoader(width: 40, height: 40),
            ],
          ),
          const SizedBox(height: 20),
          // List Items Skeleton
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => SkeletonLoader(
                  width: double.infinity, height: 80, borderRadius: 16),
            ),
          )
        ],
      ),
    );
  }

  /// Builds the main loaded content of the dashboard.
  Widget _buildDashboardContent(BuildContext context, PortfolioLoaded state,
      SettingsProvider settings, ThemeData theme) {
    final fmt = NumberFormat.currency(symbol: settings.currencySymbol);
    final rate = settings.exchangeRate;
    final assets = state.assets;
    final isEmpty = assets.isEmpty;

    final balance = state.stats.totalBalance * rate;
    final profit = state.stats.totalProfitLoss * rate;
    final risk = state.stats.riskScore;

    return Column(
      children: [
        // Header / App Bar Custom
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SmartVault Pro',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor(theme),
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings,
                    color: textColor(theme).withValues(alpha: 0.7)),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 1. Glassmorphism Balance Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassmorphicContainer(
            height: 180,
            width: double.infinity,
            blur: 20,
            border: 1,
            color: theme.primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('total_balance'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fmt.format(balance),
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Profit Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: profit >= 0
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: profit >= 0
                                    ? Colors.green.withValues(alpha: 0.5)
                                    : Colors.red.withValues(alpha: 0.5))),
                        child: Row(
                          children: [
                            Icon(
                              profit >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: profit >= 0 ? Colors.green : Colors.red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fmt.format(profit),
                              style: TextStyle(
                                color: profit >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Risk Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.security,
                                color: Colors.orangeAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Risk: $risk/10',
                              style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Portfolio Distribution Chart
        if (!isEmpty)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GlassmorphicContainer(
              height: 150, // Compact chart
              width: double.infinity,
              color: (theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  .withValues(alpha: 0.05),
              child: Row(
                children: [
                  Expanded(
                    child: PortfolioPieChart(assets: assets),
                  ),
                ],
              ),
            ),
          ),

        // List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('your_assets'),
                style: theme.textTheme.titleLarge?.copyWith(
                    color: textColor(theme), fontWeight: FontWeight.bold),
              ),
              // Search / Add Button
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/search'),
                child: GlassmorphicContainer(
                  width: 40,
                  height: 40,
                  borderRadius: 12,
                  child:
                      Center(child: Icon(Icons.add, color: textColor(theme))),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Asset List
        Expanded(
          child: isEmpty
              ? _buildEmptyState(context, theme)
              : _buildAssetList(context, assets, theme, fmt, rate),
        ),
      ],
    );
  }

  /// Builds the empty state UI when no assets are present.
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: textColor(theme).withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          Text(
            tr('portfolio_empty'),
            style: TextStyle(
                color: textColor(theme).withValues(alpha: 0.5), fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: Text(tr('add_first_asset'),
                style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  /// Builds the list of investment assets.
  Widget _buildAssetList(BuildContext context, List<InvestmentAsset> assets,
      ThemeData theme, NumberFormat fmt, double rate) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final isPositive = (asset.priceChange24h ?? 0) >= 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: (theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                    .withValues(alpha: 0.05)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/asset_detail',
                arguments: asset,
              );
            },
            child: Row(
              children: [
                // Logo with Hero
                Hero(
                  tag: 'asset_logo_${asset.id}',
                  child: CircleAvatar(
                    backgroundColor: Colors.white10,
                    backgroundImage: asset.imageUrl != null
                        ? CachedNetworkImageProvider(asset.imageUrl!)
                        : null,
                    child:
                        asset.imageUrl == null ? Text(asset.symbol[0]) : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Ticker & Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.symbol.toUpperCase(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor(theme)),
                      ),
                      Text(
                        asset.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor(theme).withValues(alpha: 0.5)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Sparkline (Middle)
                if (asset.lastSevenDaysPrices.isNotEmpty)
                  SparklineWidget(
                    data: asset.lastSevenDaysPrices,
                    isPositive: isPositive,
                    width: 60,
                    height: 30,
                  )
                else
                  // Placeholder line if no spark data
                  Container(
                    width: 60,
                    height: 2,
                    color: Colors.black12,
                  ),

                const SizedBox(width: 12),

                // Price & Holdings
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt.format((asset.currentPrice ?? 0.0) * rate),
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: textColor(theme)),
                    ),
                    Text(
                      '${asset.amount} ${asset.unitLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor(theme).withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color textColor(ThemeData theme) =>
      theme.brightness == Brightness.dark ? Colors.white : Colors.black;
}
