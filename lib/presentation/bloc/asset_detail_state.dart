import 'package:equatable/equatable.dart';
import '../../domain/entities/asset_detail.dart';

abstract class AssetDetailState extends Equatable {
  final String selectedPeriod;

  const AssetDetailState({this.selectedPeriod = '1W'});

  @override
  List<Object> get props => [selectedPeriod];
}

class DetailInitial extends AssetDetailState {}

class DetailLoading extends AssetDetailState {
  const DetailLoading({super.selectedPeriod});
}

class DetailLoaded extends AssetDetailState {
  final AssetDetail detail;
  const DetailLoaded(this.detail, {super.selectedPeriod});

  @override
  List<Object> get props => [detail, selectedPeriod];
}

class DetailError extends AssetDetailState {
  final String message;
  const DetailError(this.message, {super.selectedPeriod});

  @override
  List<Object> get props => [message, selectedPeriod];
}
