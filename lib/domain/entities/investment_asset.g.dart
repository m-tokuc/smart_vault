// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_asset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentAssetAdapter extends TypeAdapter<InvestmentAsset> {
  @override
  final int typeId = 0;

  @override
  InvestmentAsset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentAsset(
      id: fields[0] as String,
      symbol: fields[1] as String,
      name: fields[2] as String,
      amount: fields[3] as double,
      averagePrice: fields[4] as double,
      imageUrl: fields[5] as String?,
      currentPrice: fields[6] as double?,
      priceChange24h: fields[7] as double?,
      type: fields[8] as AssetType,
      sector: fields[9] as String?,
      riskScore: fields[10] as double,
      volatility: fields[11] as double,
      lastSevenDaysPrices: (fields[12] as List).cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentAsset obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.averagePrice)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.currentPrice)
      ..writeByte(7)
      ..write(obj.priceChange24h)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.sector)
      ..writeByte(10)
      ..write(obj.riskScore)
      ..writeByte(11)
      ..write(obj.volatility)
      ..writeByte(12)
      ..write(obj.lastSevenDaysPrices);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentAssetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AssetTypeAdapter extends TypeAdapter<AssetType> {
  @override
  final int typeId = 1;

  @override
  AssetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AssetType.crypto;
      case 1:
        return AssetType.stock;
      case 2:
        return AssetType.metal;
      case 3:
        return AssetType.forex;
      case 4:
        return AssetType.fund;
      case 5:
        return AssetType.commodity;
      case 6:
        return AssetType.currency;
      case 7:
        return AssetType.other;
      default:
        return AssetType.crypto;
    }
  }

  @override
  void write(BinaryWriter writer, AssetType obj) {
    switch (obj) {
      case AssetType.crypto:
        writer.writeByte(0);
        break;
      case AssetType.stock:
        writer.writeByte(1);
        break;
      case AssetType.metal:
        writer.writeByte(2);
        break;
      case AssetType.forex:
        writer.writeByte(3);
        break;
      case AssetType.fund:
        writer.writeByte(4);
        break;
      case AssetType.commodity:
        writer.writeByte(5);
        break;
      case AssetType.currency:
        writer.writeByte(6);
        break;
      case AssetType.other:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
