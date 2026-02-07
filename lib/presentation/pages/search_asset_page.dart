import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/settings_provider.dart';
import '../../core/utils/localization_utils.dart';
import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_event.dart';
import '../bloc/search/search_bloc.dart';
import '../bloc/search/search_event.dart';
import '../bloc/search/search_state.dart';
import '../../domain/entities/investment_asset.dart'; // Import for AssetType

class SearchAssetPage extends StatefulWidget {
  const SearchAssetPage({super.key});

  @override
  State<SearchAssetPage> createState() => _SearchAssetPageState();
}

class _SearchAssetPageState extends State<SearchAssetPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<SearchBloc>().add(OnQueryChanged(_searchController.text));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: tr('search_assets'),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: InputBorder.none,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          } else if (state is SearchError) {
            return Center(
                child: Text(state.message,
                    style: const TextStyle(color: Colors.white)));
          } else if (state is SearchLoaded) {
            return ListView.builder(
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final asset = state.results[index];
                return ListTile(
                  leading: asset.imageUrl != null
                      ? CircleAvatar(
                          backgroundColor: Colors.white10,
                          backgroundImage:
                              CachedNetworkImageProvider(asset.imageUrl!),
                        )
                      : CircleAvatar(child: Text(asset.symbol[0])),
                  title: Text(asset.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(asset.symbol.toUpperCase(),
                      style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.greenAccent),
                    onPressed: () => _showAddDialog(context, asset),
                  ),
                );
              },
            );
          }
          return Center(
              child: Text(tr('start_typing'),
                  style: const TextStyle(color: Colors.white54)));
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, InvestmentAsset assetModel) {
    final amountController = TextEditingController();
    final priceController = TextEditingController(
        text: assetModel.currentPrice?.toString() ?? '0.0');

    // Default to existing type, or Crypto if not specified
    AssetType selectedType = assetModel.type;

    // Helper to determine label
    String getAmountLabel(AssetType type) {
      switch (type) {
        case AssetType.metal:
          return 'Grams (g)';
        case AssetType.stock:
          return 'Lots / Shares';
        case AssetType.crypto:
          return 'Amount (${assetModel.symbol})';
        default:
          return 'Amount';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F3C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${tr("add_to_portfolio")}: ${assetModel.name}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 20),

              // Asset Type Dropdown
              DropdownButtonFormField<AssetType>(
                value: selectedType,
                dropdownColor: const Color(0xFF2D344B),
                decoration: const InputDecoration(
                  labelText: 'Asset Type',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
                items: AssetType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 12),

              // Dynamic Amount Field
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: getAmountLabel(selectedType),
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: tr('average_buy_price'),
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7)),
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  if (amount > 0) {
                    context.read<PortfolioBloc>().add(AddAssetEvent(
                          id: assetModel.id,
                          symbol: assetModel.symbol,
                          name: assetModel.name,
                          amount: amount,
                          price: price,
                          imageUrl: assetModel.imageUrl,
                          type: selectedType, // Use selected type
                        ));
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  }
                },
                child: Text(tr('add_to_portfolio'),
                    style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }
}
