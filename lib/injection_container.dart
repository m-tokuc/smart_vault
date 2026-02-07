import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/ai/ai_service.dart'; // NEW
import 'core/ai/context_builder.dart'; // NEW
import 'core/auth/auth_service.dart'; // NEW
import 'data/datasources/asset_local_datasource.dart';
import 'data/datasources/asset_remote_datasource.dart';
import 'data/datasources/binance_socket_service.dart';
import 'data/datasources/portfolio_history_local_datasource.dart';
import 'data/models/investment_asset_model.dart';
import 'data/repositories/investment_repository_impl.dart';
import 'domain/repositories/investment_repository.dart';
import 'domain/usecases/add_asset.dart';
import 'domain/usecases/delete_asset.dart';
import 'domain/usecases/get_portfolio.dart';
import 'domain/usecases/get_asset_detail.dart';
import 'domain/usecases/get_popular_assets.dart';
import 'domain/usecases/search_assets.dart';
import 'domain/usecases/calculate_portfolio_statistics.dart';
import 'domain/usecases/track_portfolio_history.dart';
import 'domain/usecases/get_ai_advice.dart'; // NEW
import 'presentation/bloc/asset_detail_bloc.dart';
import 'presentation/bloc/portfolio_bloc.dart';
import 'presentation/bloc/search/search_bloc.dart';
import 'presentation/bloc/settings_bloc.dart';
import 'presentation/bloc/advisor/advisor_bloc.dart';

/// Service Locator instance using `get_it`.
///
/// Used to access registered singletons and factories throughout the app.
final sl = GetIt.instance;

/// Initializes the Trusted Dependency Injection container.
///
/// Registers all dependencies in the following order:
/// 1. External (Hive, Dio, Key Services)
/// 2. Data Sources (Local, Remote)
/// 3. Repositories
/// 4. Use Cases
/// 5. BLoCs (State Management)
Future<void> init() async {
  // ===========================================================================
  // 1. External & Core Services
  // ===========================================================================
  await Hive.initFlutter();
  Hive.registerAdapter(InvestmentAssetAdapter());

  final assetBox = await Hive.openBox<InvestmentAssetModel>('assets');
  final historyBox = await Hive.openBox('portfolio_history');

  sl.registerLazySingleton(() => assetBox);
  sl.registerLazySingleton(() => historyBox, instanceName: 'historyBox');
  sl.registerLazySingleton(() => Dio());

  // Real-time Crypto Prices
  sl.registerLazySingleton(() => BinanceWebSocketService());

  // AI & Auth Facades
  // NOTE: Providing a default API key for demo purposes. In production, use .env or secure storage.
  // TODO: Replace 'YOUR_API_KEY_HERE' with your valid Google Gemini API Key.
  const String _kGeminiApiKey = 'YOUR_API_KEY_HERE';
  sl.registerLazySingleton(
      () => AIService(apiKey: _kGeminiApiKey));
  sl.registerLazySingleton(() => PortfolioContextBuilder());
  sl.registerLazySingleton(() => AuthService());

  // ===========================================================================
  // 2. Data Sources
  // ===========================================================================
  sl.registerLazySingleton<AssetLocalDataSource>(
    () => AssetLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AssetRemoteDataSource>(
    () => AssetRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<PortfolioHistoryLocalDataSource>(
    () => PortfolioHistoryLocalDataSource(sl(instanceName: 'historyBox')),
  );

  // ===========================================================================
  // 3. Repositories
  // ===========================================================================
  sl.registerLazySingleton<InvestmentRepository>(
    () => InvestmentRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // ===========================================================================
  // 4. Use Cases (Domain Logic)
  // ===========================================================================
  sl.registerLazySingleton(() => GetPortfolio(sl()));
  sl.registerLazySingleton(() => AddAsset(sl()));
  sl.registerLazySingleton(() => DeleteAsset(sl()));
  sl.registerLazySingleton(() => GetAssetDetail(sl()));
  sl.registerLazySingleton(() => GetPopularAssets(sl()));
  sl.registerLazySingleton(() => SearchAssets(sl()));

  // Analytics & AI
  sl.registerLazySingleton(() => CalculatePortfolioStatistics());
  sl.registerLazySingleton(() => TrackPortfolioHistory(sl()));
  sl.registerLazySingleton(() => GetAIAdvice(sl(), sl()));

  // ===========================================================================
  // 5. BLoCs (Presentation Layer)
  // ===========================================================================
  // Portfolio Management
  sl.registerFactory(
    () => PortfolioBloc(
      getPortfolio: sl(),
      addAsset: sl(),
      deleteAsset: sl(),
      binanceService: sl(),
      calculateStats: sl(),
      trackHistory: sl(),
    ),
  );

  // Detailed Asset View
  sl.registerFactory(
    () => AssetDetailBloc(
      getAssetDetail: sl(),
    ),
  );

  // Asset Search & Discovery
  sl.registerFactory(
    () => SearchBloc(
      searchAssets: sl(),
      getPopularAssets: sl(),
    ),
  );

  // App Settings
  sl.registerFactory(() => SettingsBloc());

  // AI Advisor Chat
  sl.registerFactory(
    () => AdvisorBloc(
      aiService: sl(),
    ),
  );
}
