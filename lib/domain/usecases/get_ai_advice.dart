import '../../core/ai/ai_service.dart';
import '../../core/ai/context_builder.dart';
import '../entities/investment_asset.dart';
import '../entities/portfolio_stats.dart';

class GetAIAdvice {
  final AIService aiService;
  final PortfolioContextBuilder contextBuilder;

  GetAIAdvice(this.aiService, this.contextBuilder);

  Future<String> execute({
    required List<InvestmentAsset> assets,
    required PortfolioStats stats,
    List<String> news = const [],
  }) async {
    // 1. Build Context
    String context = contextBuilder.buildPortfolioContext(assets, stats);
    if (news.isNotEmpty) {
      context = contextBuilder.appendNewsContext(context, news);
    }

    // 2. Construct System Prompt
    final prompt = """
You are a professional, sharp, and concise Financial Investment Advisor. 
Analyze the following portfolio context and provide actionable advice.
Focus on Risk Management, Diversification gaps, and potential opportunities based on the news (if any).
Do NOT provide generic disclaimers like "I am an AI". Assume the user knows the risks.
Answer in Markdown format. Keep it under 200 words. Bullet points are preferred.

$context
""";

    // 3. Call AI
    return await aiService.generateAdvice(prompt);
  }
}
