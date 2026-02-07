import 'package:equatable/equatable.dart';

// Simple model for UI
class ChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  List<Object> get props => [text, isUser, timestamp];
}

abstract class AdvisorState extends Equatable {
  final List<ChatMessage> messages;

  const AdvisorState({this.messages = const []});

  @override
  List<Object> get props => [messages];
}

class AdvisorInitial extends AdvisorState {}

class AdvisorLoading extends AdvisorState {
  const AdvisorLoading({super.messages});
}

class AdvisorReady extends AdvisorState {
  // Chat is active, waiting for input or displaying history
  const AdvisorReady({super.messages});
}

class AdvisorAnswering extends AdvisorState {
  // Thinking...
  const AdvisorAnswering({super.messages});
}

class AdvisorError extends AdvisorState {
  final String error;

  const AdvisorError(this.error, {super.messages});

  @override
  List<Object> get props => [error, messages];
}
