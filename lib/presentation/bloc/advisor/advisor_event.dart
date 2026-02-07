import 'package:equatable/equatable.dart';

abstract class AdvisorEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class InitializeChat extends AdvisorEvent {
  // We can pass context here if needed, or just rely on BLoC reading other providers
  final String? initialContext;

  InitializeChat({this.initialContext});

  @override
  List<Object> get props => [initialContext ?? ''];
}

class SendMessage extends AdvisorEvent {
  final String message;

  SendMessage(this.message);

  @override
  List<Object> get props => [message];
}
