import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/localization_utils.dart';

// Events
abstract class SettingsEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ChangeCurrency extends SettingsEvent {
  final String currencyCode;
  ChangeCurrency(this.currencyCode);

  @override
  List<Object> get props => [currencyCode];
}

class ChangeLanguage extends SettingsEvent {
  final Locale locale;
  ChangeLanguage(this.locale);

  @override
  List<Object> get props => [locale];
}

// State
class SettingsState extends Equatable {
  final String currencyCode; // USD, TRY, EUR...
  final String currencySymbol; // $, ₺, €...
  final double exchangeRate; // Relative to USD
  final Locale locale; // en, tr, de...

  const SettingsState({
    required this.currencyCode,
    required this.currencySymbol,
    required this.exchangeRate,
    required this.locale,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      currencyCode: 'USD',
      currencySymbol: '\$',
      exchangeRate: 1.0,
      locale: Locale('en'),
    );
  }

  SettingsState copyWith({
    String? currencyCode,
    String? currencySymbol,
    double? exchangeRate,
    Locale? locale,
  }) {
    return SettingsState(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object> get props =>
      [currencyCode, currencySymbol, exchangeRate, locale];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsState.initial()) {
    on<ChangeCurrency>(_onChangeCurrency);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  void _onChangeCurrency(ChangeCurrency event, Emitter<SettingsState> emit) {
    String symbol;
    double rate;

    // Hardcoded Rates for Demo (Base: USD)
    switch (event.currencyCode) {
      case 'TRY':
        symbol = '₺';
        rate = 34.50;
        break;
      case 'EUR':
        symbol = '€';
        rate = 0.92;
        break;
      case 'GBP':
        symbol = '£';
        rate = 0.79;
        break;
      case 'JPY':
        symbol = '¥';
        rate = 148.0;
        break;
      case 'USD':
      default:
        symbol = '\$';
        rate = 1.0;
        break;
    }

    emit(state.copyWith(
      currencyCode: event.currencyCode,
      currencySymbol: symbol,
      exchangeRate: rate,
    ));
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event, Emitter<SettingsState> emit) async {
    await LocalizationUtils.load(event.locale);
    emit(state.copyWith(locale: event.locale));
  }
}
