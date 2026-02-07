import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../../domain/usecases/search_assets.dart';
import '../../../domain/usecases/get_popular_assets.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchAssets searchAssets;
  final GetPopularAssets getPopularAssets;

  SearchBloc({
    required this.searchAssets,
    required this.getPopularAssets,
  }) : super(SearchInitial()) {
    on<OnQueryChanged>((event, emit) async {
      emit(SearchLoading());
      try {
        if (event.query.isEmpty) {
          final results = await getPopularAssets.execute();
          emit(SearchLoaded(results));
        } else {
          final results = await searchAssets.execute(event.query);
          emit(SearchLoaded(results));
        }
      } catch (e) {
        emit(const SearchError("Arama yapılamadı"));
      }
    }, transformer: (events, mapper) {
      return events
          .debounceTime(const Duration(milliseconds: 500))
          .switchMap(mapper);
    });

    // Add initial event to load popular assets AFTER registering handler
    add(const OnQueryChanged(''));
  }
}
