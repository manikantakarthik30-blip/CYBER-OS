import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';

class AdvisorMessage {
  final String role; // 'user' or 'model'
  final String content;
  final DateTime timestamp;

  AdvisorMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AdvisorState {
  final List<AdvisorMessage> messages;
  final bool isThinking;

  AdvisorState({
    required this.messages,
    this.isThinking = false,
  });

  AdvisorState copyWith({
    List<AdvisorMessage>? messages,
    bool? isThinking,
  }) {
    return AdvisorState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}

final advisorControllerProvider =
    StateNotifierProvider<AdvisorController, AdvisorState>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return AdvisorController(gemini);
});

class AdvisorController extends StateNotifier<AdvisorState> {
  final GeminiService _geminiService;

  AdvisorController(this._geminiService)
      : super(
          AdvisorState(
            messages: [
              AdvisorMessage(
                role: 'model',
                content:
                    'CYBER_OS Neural Security Advisor initialized. All threat signatures, MCP protocols, and CVE indices loaded. How may I assist your triage operations today?',
              ),
            ],
          ),
        );

  Future<void> sendUserMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.isThinking) return;

    final userMsg = AdvisorMessage(role: 'user', content: query);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isThinking: true,
    );

    final historyForApi = state.messages.map((m) {
      return {'role': m.role, 'content': m.content};
    }).toList();

    final response = await _geminiService.chatWithAdvisor(
      conversationHistory: historyForApi,
    );

    final modelMsg = AdvisorMessage(
      role: 'model',
      content: response ?? 'Connection lost to AI Advisor engine.',
    );

    state = state.copyWith(
      messages: [...state.messages, modelMsg],
      isThinking: false,
    );
  }

  void clearConversation() {
    state = AdvisorState(
      messages: [
        AdvisorMessage(
          role: 'model',
          content: 'Conversation cleared. Neural Security Advisor ready.',
        ),
      ],
    );
  }
}
