import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../bloc/advisor/advisor_bloc.dart';
import '../bloc/advisor/advisor_event.dart';
import '../bloc/advisor/advisor_state.dart';
import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_state.dart';
import '../../../core/ai/context_builder.dart';
import '../../../injection_container.dart' as di;
import '../widgets/glassmorphic_container.dart';

class AdvisorChatPage extends StatefulWidget {
  const AdvisorChatPage({super.key});

  @override
  State<AdvisorChatPage> createState() => _AdvisorChatPageState();
}

class _AdvisorChatPageState extends State<AdvisorChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.15),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Financial Advisor',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        onPressed: () {
                          // Reset chat logic if needed
                        },
                      )
                    ],
                  ),
                ),

                // Chat Area
                Expanded(
                  child: BlocProvider(
                    create: (context) {
                      final bloc = di.sl<AdvisorBloc>();
                      final portfolioState =
                          context.read<PortfolioBloc>().state;
                      String initialContext =
                          "User is asking for financial advice.";

                      if (portfolioState is PortfolioLoaded) {
                        final builder = di.sl<PortfolioContextBuilder>();
                        initialContext = builder.buildPortfolioContext(
                            portfolioState.assets, portfolioState.stats);
                        initialContext +=
                            "\n\nUser Context: The user wants to chat about their investments. Be professional, helpful, and concise.";
                      }

                      bloc.add(InitializeChat(initialContext: initialContext));
                      return bloc;
                    },
                    child: BlocBuilder<AdvisorBloc, AdvisorState>(
                      builder: (context, state) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => _scrollToBottom());

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: state.messages.length +
                                    (state is AdvisorAnswering ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= state.messages.length) {
                                    return _buildTypingIndicator(theme);
                                  }

                                  final msg = state.messages[index];
                                  return _buildMessageBubble(msg, theme);
                                },
                              ),
                            ),

                            // Input Area (Glassmorphic)
                            Container(
                              margin: const EdgeInsets.all(16),
                              child: GlassmorphicContainer(
                                width: double.infinity,
                                borderRadius: 24,
                                blur: 20,
                                border: 1,
                                color: theme.cardColor.withOpacity(0.6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _textController,
                                          focusNode: _focusNode,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Ask about your portfolio...',
                                            hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5)),
                                            border: InputBorder.none,
                                          ),
                                          onSubmitted: (value) =>
                                              _sendMessage(context, value),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.send,
                                            color: primaryColor),
                                        onPressed: () => _sendMessage(
                                            context, _textController.text),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    context.read<AdvisorBloc>().add(SendMessage(text));
    _textController.clear();
    _focusNode.requestFocus();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage msg, ThemeData theme) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? theme.primaryColor : theme.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              MarkdownBody(
                data: msg.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white, fontSize: 15),
                  listBullet: const TextStyle(color: Colors.white),
                  strong: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            else
              Text(msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              DateFormat('HH:mm').format(msg.timestamp),
              style:
                  TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.zero,
          ),
        ),
        child: SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 24,
                      height: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
