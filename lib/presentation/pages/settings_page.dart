import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/localization_utils.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch settings from Provider instead of Bloc
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings')),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildDropdownTile(
              context,
              title: tr('currency'),
              value: settings.currency,
              items: ['USD', 'TRY', 'EUR', 'GBP', 'JPY'],
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsProvider>().setCurrency(val);
                }
              },
              itemBuilder: (code) {
                String symbol = '';
                switch (code) {
                  case 'USD':
                    symbol = '\$';
                    break;
                  case 'TRY':
                    symbol = '₺';
                    break;
                  case 'EUR':
                    symbol = '€';
                    break;
                  case 'GBP':
                    symbol = '£';
                    break;
                  case 'JPY':
                    symbol = '¥';
                    break;
                }
                return '$code ($symbol)';
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownTile(
              context,
              title: tr('language'),
              value: settings.locale.languageCode,
              items: ['en', 'tr', 'de', 'fr', 'es', 'ru', 'ja', 'zh'],
              onChanged: (val) {
                if (val != null) {
                  var locale = Locale(val);
                  context.read<SettingsProvider>().setLocale(locale);
                  // Ensure Utils load the new strings
                  LocalizationUtils.load(locale);
                }
              },
              itemBuilder: (code) {
                String flag = '';
                String name = '';
                switch (code) {
                  case 'en':
                    flag = '🇺🇸';
                    name = 'English';
                    break;
                  case 'tr':
                    flag = '🇹🇷';
                    name = 'Türkçe';
                    break;
                  case 'de':
                    flag = '🇩🇪';
                    name = 'Deutsch';
                    break;
                  case 'fr':
                    flag = '🇫🇷';
                    name = 'Français';
                    break;
                  case 'es':
                    flag = '🇪🇸';
                    name = 'Español';
                    break;
                  case 'ru':
                    flag = '🇷🇺';
                    name = 'Русский';
                    break;
                  case 'ja':
                    flag = '🇯🇵';
                    name = '日本語';
                    break;
                  case 'zh':
                    flag = '🇨🇳';
                    name = '中文';
                    break;
                }
                return '$flag $name';
              },
            ),

            const SizedBox(height: 16),

            // Theme Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        settings.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        settings.themeMode == ThemeMode.dark
                            ? 'Dark Mode'
                            : 'Light Mode', // Localization key needed ideally
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                  Switch(
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (val) {
                      context.read<SettingsProvider>().toggleTheme(val);
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context, {
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF2D3447),
              onChanged: onChanged,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    itemBuilder(item),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
