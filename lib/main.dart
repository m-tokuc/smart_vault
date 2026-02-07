import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'injection_container.dart' as di;
import 'presentation/bloc/portfolio_bloc.dart';
import 'presentation/bloc/portfolio_event.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/providers/settings_provider.dart';
import 'config/theme/app_theme.dart';

import 'presentation/pages/login_page.dart';
import 'presentation/pages/search_asset_page.dart';
import 'presentation/pages/settings_page.dart'; // Need to create/verify this next
import 'presentation/pages/asset_detail_page.dart';
import 'presentation/pages/advisor_chat_page.dart';
import 'domain/entities/investment_asset.dart';

import 'presentation/bloc/search/search_bloc.dart';
import 'presentation/bloc/asset_detail_bloc.dart';
import 'presentation/bloc/asset_detail_event.dart'; // Ensure event is imported

/// Main entry point for the SmartVault application.
///
/// This file initializes the Flutter binding, dependency injection, and the root widget.
/// It also sets up global providers and routing for the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // Initialize Dependency Injection

  runApp(
    // MultiProvider initializes global providers that need to be accessible
    // throughout the widget tree.
    MultiProvider(
      providers: [
        // 1. SettingsProvider: Manages app-wide settings like theme and currency.
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // 2. PortfolioBloc: Manages the main portfolio data state.
        // It is initialized immediately to fetch data on startup.
        BlocProvider(
            create: (_) => di.sl<PortfolioBloc>()..add(LoadPortfolio())),

        // 3. SearchBloc: Manages the asset search functionality.
        BlocProvider(create: (_) => di.sl<SearchBloc>()),
      ],
      child: const SmartVaultApp(),
    ),
  );
}

/// The root widget of the SmartVault application.
///
/// It configures the [MaterialApp] with theme settings, localization delegates,
/// and route definitions.
class SmartVaultApp extends StatelessWidget {
  const SmartVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes in SettingsProvider to rebuild the app when theme or locale changes.
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'SmartVault',
      debugShowCheckedModeBanner: false,

      // --- Localization Configuration ---
      locale: settings.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('tr'), // Turkish
        Locale('de'), // German
        Locale('fr'), // French
        Locale('es'), // Spanish
        Locale('ru'), // Russian
        Locale('ja'), // Japanese
        Locale('zh'), // Chinese
      ],

      // --- Theme Configuration ---
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode, // Dynamic theme switching

      // --- Routing Configuration ---
      initialRoute: '/login', // Start at Login Page
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/search': (context) => const SearchAssetPage(),
        '/asset_detail': (context) {
          // Pass the InvestmentAsset argument to the detail page
          final asset =
              ModalRoute.of(context)!.settings.arguments as InvestmentAsset;
          return BlocProvider(
            create: (_) => di.sl<AssetDetailBloc>(),
            child: AssetDetailPage(asset: asset),
          );
        },
        '/settings': (context) => const SettingsPage(),
        '/advisor_chat': (context) => const AdvisorChatPage(),
      },
      home: const LoginPage(),
    );
  }
}
