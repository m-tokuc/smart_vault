import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/ai/ai_service.dart';
import '../../../../core/ai/context_builder.dart';
import '../../../../domain/entities/investment_asset.dart';
import '../../../../domain/entities/portfolio_stats.dart';
import '../../../../domain/usecases/get_portfolio.dart'; // Or access PortfolioBloc state directly? No, keep it clean.
import 'advisor_event.dart';
import 'advisor_state.dart';

// We need Portfolio Data to initialize context
class AdvisorBloc extends Bloc<AdvisorEvent, AdvisorState> {
  final AIService aiService;

  // We'll keep messages in memory here
  List<ChatMessage> _messages = [];

  AdvisorBloc({
    required this.aiService,
  }) : super(AdvisorInitial()) {
    on<InitializeChat>(_onInitializeChat);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onInitializeChat(
    InitializeChat event,
    Emitter<AdvisorState> emit,
  ) async {
    emit(AdvisorLoading());
    try {
      // 1. Initialize AI Session with System Prompt
      aiService.startChat(
          event.initialContext ?? "You are a helpful Financial Advisor.");

      // 2. Add Welcome Message
      _messages = [
        ChatMessage(
          text:
              "Hello! I'm your AI Financial Advisor. I have access to your current portfolio. How can I assist you today?",
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];

      emit(AdvisorReady(messages: List.from(_messages)));
    } catch (e) {
      emit(AdvisorError("Failed to initialize chat: $e"));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AdvisorState> emit,
  ) async {
    // 1. Add User Message
    final userMsg = ChatMessage(
      text: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    emit(AdvisorAnswering(messages: List.from(_messages)));

    try {
      // 2. Get AI Response
      final responseText = await aiService.sendMessage(event.message);

      // 3. Add AI Message
      final aiMsg = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);

      emit(AdvisorReady(messages: List.from(_messages)));
    } catch (e) {
      // Revert to ready but show error
      emit(AdvisorError("Failed to send message: $e",
          messages: List.from(_messages)));
    }
  }
}
