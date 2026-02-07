import 'package:hive/hive.dart';
import '../../domain/entities/investment_asset.dart';

class InvestmentAssetModel extends InvestmentAsset {
  const InvestmentAssetModel({
    required super.id,
    required super.symbol,
    required super.name,
    required super.type,
    required super.amount,
    required super.averagePrice,
    required super.currentPrice,
    super.imageUrl,
    super.sector,
    super.riskScore,
    super.volatility,
    super.lastSevenDaysPrices,
    super.isOfflineData,
  });

  factory InvestmentAssetModel.fromEntity(InvestmentAsset asset) {
    return InvestmentAssetModel(
      id: asset.id,
      symbol: asset.symbol,
      name: asset.name,
      type: asset.type,
      amount: asset.amount,
      averagePrice: asset.averagePrice,
      currentPrice: asset.currentPrice,
      imageUrl: asset.imageUrl,
      sector: asset.sector,
      riskScore: asset.riskScore,
      volatility: asset.volatility,
      lastSevenDaysPrices: asset.lastSevenDaysPrices,
      isOfflineData: asset.isOfflineData,
    );
  }

  InvestmentAsset toEntity() {
    return InvestmentAsset(
      id: id,
      symbol: symbol,
      name: name,
      type: type,
      amount: amount,
      averagePrice: averagePrice,
      currentPrice: currentPrice,
      imageUrl: imageUrl,
      sector: sector,
      riskScore: riskScore,
      volatility: volatility,
      lastSevenDaysPrices: lastSevenDaysPrices,
      isOfflineData: isOfflineData,
    );
  }

  factory InvestmentAssetModel.fromJson(Map<String, dynamic> json) {
    // This is a basic parser, will be enhanced by the Smart Router mapping
    // which injects additional fields.
    return InvestmentAssetModel(
      id: json['id'],
      symbol: (json['symbol'] as String).toUpperCase(),
      name: json['name'],
      type: AssetType.crypto, // Default
      amount: 0,
      averagePrice: 0,
      currentPrice: 0,
      imageUrl: json['thumb'] ?? json['large'],
    );
  }
}

class InvestmentAssetAdapter extends TypeAdapter<InvestmentAssetModel> {
  @override
  final int typeId = 0;

  @override
  InvestmentAssetModel read(BinaryReader reader) {
    // Keep it backward compatible or reset data if needed in dev
    // Reading fields in order
    final id = reader.readString();
    final symbol = reader.readString();
    final name = reader.readString();
    final typeStr = reader.readString();
    final amount = reader.readDouble();
    final averagePrice = reader.readDouble();
    final currentPrice = reader.readDouble();

    // Optional ImageUrl
    String? imageUrl;
    if (reader.readBool()) {
      imageUrl = reader.readString();
    }

    // New Fields (check if available or use defaults if reading old data?)
    // Hive binary reader expects data to be there if we just call read.
    // To handle migration safely without crashing on old boxes, we should use
    // Hive's built-in migration or just clear the box.
    // For this dev session, we'll assume we can rebuild or add defaults logic if reader has enough bytes?
    // Actually, Hive strictly reads bytes. If the schema changed, standard practice is to change TypeId or
    // handle migration manually.
    // BUT since we control the environment, we will just read defaults for now or let it fail/rebuild.
    // A primitive migration strategy:
    // We can't know if the bytes are there easily.
    // Let's assume we simply wipe the box or use a new box name in `injection_container.dart` to avoid conflict.

    // Let's try to read them. If it fails, we catch it? No, BinaryReader doesn't throw easily recoverable errors.
    // I will add a method to clear DB in init if needed, but for now let's write the full reader logic.

    String? sector;
    // We need to implement a safer read or just write everything.
    // CAUTION: This manual adapter is risky if fields change often.
    // Ideally we rely on @HiveType generation for the Entity, and wrap it.
    // But since we are here:

    // To simplify: I will assume a fresh install or data wipe is acceptable for this MAJOR upgrade.

    if (reader.availableBytes > 0) {
      sector = reader.readBool() ? reader.readString() : null;
    }
    double riskScore = 5.0;
    if (reader.availableBytes > 0) riskScore = reader.readDouble();

    double volatility = 0.0;
    if (reader.availableBytes > 0) volatility = reader.readDouble();

    List<double> last7Days = [];
    if (reader.availableBytes > 0) {
      int len = reader.readInt();
      for (int i = 0; i < len; i++) {
        last7Days.add(reader.readDouble());
      }
    }

    AssetType type = AssetType.crypto;
    try {
      type = AssetType.values
          .firstWhere((e) => e.name == typeStr, orElse: () => AssetType.crypto);
    } catch (_) {}

    return InvestmentAssetModel(
      id: id,
      symbol: symbol,
      name: name,
      type: type,
      amount: amount,
      averagePrice: averagePrice,
      currentPrice: currentPrice,
      imageUrl: imageUrl,
      sector: sector,
      riskScore: riskScore,
      volatility: volatility,
      lastSevenDaysPrices: last7Days,
      isOfflineData:
          false, // Always False from Cache, until Repo marks it otherwise?
      // Ah, if we load from Cache because User opened app, it IS offline data relative to "Live".
      // But usually we load, then try to fetch.
      // Let's default false.
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentAssetModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.symbol);
    writer.writeString(obj.name);
    writer.writeString(obj.type.name);
    writer.writeDouble(obj.amount);
    writer.writeDouble(obj.averagePrice);
    writer.writeDouble(obj.currentPrice ?? 0.0);

    writer.writeBool(obj.imageUrl != null);
    if (obj.imageUrl != null) writer.writeString(obj.imageUrl!);

    // New Fields
    writer.writeBool(obj.sector != null);
    if (obj.sector != null) writer.writeString(obj.sector!);

    writer.writeDouble(obj.riskScore);
    writer.writeDouble(obj.volatility);

    writer.writeInt(obj.lastSevenDaysPrices.length);
    for (var price in obj.lastSevenDaysPrices) {
      writer.writeDouble(price);
    }
  }
}
