import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cyber_card.dart';
import '../../core/widgets/glitch_text.dart';
import 'advisor_controller.dart';

class AdvisorScreen extends ConsumerStatefulWidget {
  const AdvisorScreen({super.key});

  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _inputController.text;
    if (text.trim().isEmpty) return;

    ref.read(advisorControllerProvider.notifier).sendUserMessage(text);
    _inputController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final advisorState = ref.watch(advisorControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.void_black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlitchText(
                        text: 'AI SECURITY ADVISOR',
                        style: AppTypography.headline,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'INTERACTIVE THREAT TRIAGE & PATCH INTELLIGENCE',
                        style: AppTypography.label,
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Clear Conversation',
                    onPressed: () {
                      ref.read(advisorControllerProvider.notifier).clearConversation();
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.text_secondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Prompts Pill Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPromptChip('Explain CVE-2023-45853 in zlib'),
                    const SizedBox(width: 8),
                    _buildPromptChip('How do I secure dynamic MCP tool execution?'),
                    const SizedBox(width: 8),
                    _buildPromptChip('Best practice for Firestore rules?'),
                    const SizedBox(width: 8),
                    _buildPromptChip('How to protect against prompt reflection?'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chat Messages
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.abyss,
                    border: Border.all(color: AppColors.text_ghost.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: advisorState.messages.length + (advisorState.isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == advisorState.messages.length && advisorState.isThinking) {
                        return _buildThinkingBubble();
                      }
                      final msg = advisorState.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Input Row
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.signal_dim),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, color: AppColors.signal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.text_primary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter inquiry or vulnerability context...',
                          hintStyle: GoogleFonts.jetBrainsMono(
                            color: AppColors.text_ghost,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.signal),
                      onPressed: () => _sendMessage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return ActionChip(
      backgroundColor: AppColors.trench,
      side: const BorderSide(color: AppColors.text_ghost, width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      label: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          color: AppColors.text_secondary,
        ),
      ),
      onPressed: () => _sendMessage(label),
    );
  }

  Widget _buildMessageBubble(AdvisorMessage msg) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.signal_glow,
                border: Border.all(color: AppColors.signal),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(Icons.psychology, color: AppColors.signal, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: CyberCard(
              accentColor: isUser ? AppColors.text_secondary : AppColors.signal,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUser ? 'OPERATOR' : 'CYBER_OS ADVISOR',
                      style: GoogleFonts.rajdhani(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: isUser ? AppColors.text_secondary : AppColors.signal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      msg.content,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: AppColors.text_primary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.text_ghost),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(Icons.person, color: AppColors.text_primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.signal_glow,
              border: Border.all(color: AppColors.signal),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.psychology, color: AppColors.signal, size: 16),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.signal),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Computing threat analysis...',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.signal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
