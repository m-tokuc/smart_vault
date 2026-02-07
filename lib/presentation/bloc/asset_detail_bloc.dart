import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/asset_detail.dart';
import '../../domain/usecases/get_asset_detail.dart';
import 'asset_detail_event.dart';
import 'asset_detail_state.dart';

class AssetDetailBloc extends Bloc<AssetDetailEvent, AssetDetailState> {
  final GetAssetDetail getAssetDetail;
  String? _currentId;

  AssetDetailBloc({required this.getAssetDetail}) : super(DetailInitial()) {
    on<LoadAssetDetail>(_onLoadAssetDetail);
    on<ChangePeriod>(_onChangePeriod);
  }

  Future<void> _onLoadAssetDetail(
    LoadAssetDetail event,
    Emitter<AssetDetailState> emit,
  ) async {
    _currentId = event.id;
    emit(DetailLoading(selectedPeriod: state.selectedPeriod));
    try {
      final detail =
          await getAssetDetail.execute(event.id, period: state.selectedPeriod);
      emit(DetailLoaded(detail, selectedPeriod: state.selectedPeriod));
    } catch (e) {
      emit(DetailError(e.toString(), selectedPeriod: state.selectedPeriod));
    }
  }

  Future<void> _onChangePeriod(
    ChangePeriod event,
    Emitter<AssetDetailState> emit,
  ) async {
    if (_currentId == null) return;

    emit(DetailLoading(selectedPeriod: event.period));
    try {
      final detail =
          await getAssetDetail.execute(_currentId!, period: event.period);
      emit(DetailLoaded(detail, selectedPeriod: event.period));
    } catch (e) {
      emit(DetailError(e.toString(), selectedPeriod: event.period));
    }
  }
}
