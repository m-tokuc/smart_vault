import 'package:equatable/equatable.dart';

abstract class AssetDetailEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadAssetDetail extends AssetDetailEvent {
  final String id;
  LoadAssetDetail(this.id);
  @override
  List<Object> get props => [id];
}

class ChangePeriod extends AssetDetailEvent {
  final String period; // '1D', '1W', '1Y'
  ChangePeriod(this.period);
  @override
  List<Object> get props => [period];
}
