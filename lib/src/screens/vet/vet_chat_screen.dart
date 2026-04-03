import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/pet_provider.dart';
import '../../providers/vet_chat_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_spacing.dart';
import '../../theme/wellx_typography.dart';

/// Full Dr. Layla AI vet chat interface.
class VetChatScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;
  const VetChatScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<VetChatScreen> createState() => _VetChatScreenState();
}

class _VetChatScreenState extends ConsumerState<VetChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  bool _didSendInitial = false;
  File? _pendingImage;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    final image = _pendingImage;
    if (text.isEmpty && image == null) return;
    _controller.clear();
    setState(() => _pendingImage = null);
    ref.read(vetChatProvider.notifier).sendMessage(
          text,
          imageFile: image,
        );
    _scrollToBottom();
  }

  void _sendChip(String text) {
    ref.read(vetChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      final xfile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (xfile != null && mounted) {
        // File size check — max 10 MB
        final file = File(xfile.path);
        final bytes = await file.length();
        if (bytes > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Image is too large. Please choose a photo under 10 MB.'),
              ),
            );
          }
          return;
        }
        setState(() => _pendingImage = file);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open photo library.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(vetChatProvider);
    final pet = ref.watch(selectedPetProvider);

    // Auto-send initial prompt once
    if (!_didSendInitial &&
        widget.initialPrompt != null &&
        widget.initialPrompt!.isNotEmpty) {
      _didSendInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(vetChatProvider.notifier).sendMessage(widget.initialPrompt!);
      });
    }

    if (chatState.messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: _buildAppBar(pet?.name),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.unfocus(),
              child: chatState.messages.isEmpty && !chatState.isLoading
                  ? _buildEmptyState(pet?.name ?? 'your pet')
                  : _buildMessageList(chatState),
            ),
          ),
          if (chatState.errorMessage != null)
            _buildErrorBanner(chatState.errorMessage!),
          if (_pendingImage != null) _buildImagePreview(),
          _buildInputBar(chatState.isLoading),
        ],
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String? petName) {
    return AppBar(
      backgroundColor: WellxColors.cardSurface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: WellxColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: WellxColors.deepPurple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: WellxSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Dr. Layla',
                    style: WellxTypography.cardTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  // Online indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: WellxColors.alertGreen,
                    ),
                  ),
                ],
              ),
              if (petName != null)
                Text(
                  'Reviewing $petName\'s records',
                  style: WellxTypography.captionText.copyWith(
                    color: WellxColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (ref.read(vetChatProvider).messages.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: WellxColors.textTertiary,
            tooltip: 'Clear chat history',
            onPressed: _showClearDialog,
          ),
      ],
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
            'This will remove all messages in this conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(vetChatProvider.notifier).clearChat();
              Navigator.pop(ctx);
            },
            child: Text('Clear',
                style: TextStyle(color: WellxColors.alertRed)),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(String petName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: WellxSpacing.xl),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: WellxColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: WellxColors.deepPurple.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),
          Text('Dr. Layla', style: WellxTypography.heading),
          const SizedBox(height: WellxSpacing.xs),
          Text(
            'Pet wellness companion for $petName',
            style: WellxTypography.captionText.copyWith(
              color: WellxColors.textTertiary,
            ),
          ),
          const SizedBox(height: WellxSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: WellxSpacing.lg, vertical: WellxSpacing.sm),
            decoration: BoxDecoration(
              color: WellxColors.amberWatch.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Not a replacement for a vet. A well-informed first opinion available 24/7.',
              textAlign: TextAlign.center,
              style: WellxTypography.captionText.copyWith(
                color: WellxColors.amberWatch,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.xxl),
          _buildChipSection('SYMPTOMS', [
            "He's limping",
            "She's not eating",
            "Vomiting",
            "Drinking more than usual",
            "Lethargy",
            "Itching a lot",
          ]),
          const SizedBox(height: WellxSpacing.lg),
          _buildChipSection('QUESTIONS', [
            'What should I feed my dog?',
            'Is this symptom concerning?',
            'Medication question',
            'Review blood work results',
            'Exercise advice',
          ]),
          const SizedBox(height: WellxSpacing.lg),
          // Photo prompt
          Semantics(
            button: true,
            label: 'Share a photo with Dr. Layla',
            child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(WellxSpacing.lg),
              decoration: BoxDecoration(
                color: WellxColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WellxColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: WellxColors.deepPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded,
                        color: WellxColors.deepPurple, size: 20),
                  ),
                  const SizedBox(width: WellxSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share a Photo',
                          style: WellxTypography.chipText.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Show Dr. Layla a rash, wound, or symptom',
                          style: WellxTypography.captionText.copyWith(
                            color: WellxColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: WellxColors.textTertiary),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChipSection(String title, List<String> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: WellxSpacing.sm),
          child: Text(
            title,
            style: WellxTypography.sectionLabel.copyWith(
              color: WellxColors.textTertiary,
            ),
          ),
        ),
        Wrap(
          spacing: WellxSpacing.sm,
          runSpacing: WellxSpacing.sm,
          children: chips.map((chip) {
            return Semantics(
              button: true,
              label: chip,
              child: GestureDetector(
              onTap: () => _sendChip(chip),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: WellxColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WellxColors.border),
                ),
                child: Text(
                  chip,
                  style: WellxTypography.captionText.copyWith(
                    color: WellxColors.textPrimary,
                  ),
                ),
              ),
            ));
          }).toList(),
        ),
      ],
    );
  }

  // ── Message List ─────────────────────────────────────────────────────────

  Widget _buildMessageList(VetChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: WellxSpacing.lg,
        vertical: WellxSpacing.sm,
      ),
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length && chatState.isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(chatState.messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Semantics(
      label: '${isUser ? 'You' : 'Dr. Layla'}: ${message.content}',
      child: Padding(
      key: const Key('chat_message_bubble'),
      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: WellxColors.primaryGradient,
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: WellxSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Image bubble (if message has an attached image path)
                if (message.imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (message.content.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? WellxColors.deepPurple
                          : WellxColors.cardSurface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: WellxColors.border, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isUser
                        ? Text(
                            message.content,
                            style: WellxTypography.bodyText.copyWith(
                              color: Colors.white,
                            ),
                          )
                        : MarkdownBody(
                            data: message.content,
                            styleSheet: MarkdownStyleSheet(
                              p: WellxTypography.bodyText.copyWith(
                                color: WellxColors.textPrimary,
                                height: 1.5,
                              ),
                              strong: WellxTypography.bodyText.copyWith(
                                color: WellxColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              listBullet: WellxTypography.bodyText.copyWith(
                                color: WellxColors.textSecondary,
                              ),
                              h1: WellxTypography.heading.copyWith(fontSize: 18),
                              h2: WellxTypography.heading.copyWith(fontSize: 16),
                              h3: WellxTypography.heading.copyWith(fontSize: 14),
                              code: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: WellxColors.deepPurple,
                                backgroundColor: WellxColors.flatCardFill,
                              ),
                              blockquotePadding:
                                  const EdgeInsets.only(left: 12),
                              blockquoteDecoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: WellxColors.deepPurple
                                        .withValues(alpha: 0.3),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: WellxSpacing.sm),
        ],
      ),
    ));
  }

  // ── Typing Indicator ─────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: WellxColors.primaryGradient,
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: WellxSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: WellxColors.cardSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: WellxColors.border, width: 0.5),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Error Banner ─────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: WellxSpacing.lg,
        vertical: WellxSpacing.xs,
      ),
      padding: const EdgeInsets.all(WellxSpacing.md),
      decoration: BoxDecoration(
        color: WellxColors.alertRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, size: 16, color: WellxColors.alertRed),
          const SizedBox(width: WellxSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: WellxTypography.captionText.copyWith(
                color: WellxColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => ref.read(vetChatProvider.notifier).retryLast(),
            child: Text(
              'Retry',
              style: WellxTypography.captionText.copyWith(
                color: WellxColors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending image preview ─────────────────────────────────────────────────

  Widget _buildImagePreview() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(
          horizontal: WellxSpacing.md, vertical: WellxSpacing.sm),
      decoration: BoxDecoration(
        color: WellxColors.cardSurface,
        border: Border(top: BorderSide(color: WellxColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _pendingImage!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () => setState(() => _pendingImage = null),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: WellxColors.textPrimary,
                    ),
                    child: const Icon(Icons.close,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: WellxSpacing.md),
          Text(
            'Photo attached',
            style: WellxTypography.captionText.copyWith(
              color: WellxColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ────────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: WellxColors.cardSurface,
        border: Border(
          top: BorderSide(color: WellxColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WellxSpacing.md,
            vertical: WellxSpacing.sm,
          ),
          child: Row(
            children: [
              // Camera button
              Semantics(
                button: true,
                label: 'Attach photo',
                enabled: !isLoading,
                child: GestureDetector(
                onTap: isLoading ? null : _pickImage,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: WellxColors.flatCardFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: WellxColors.border),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 18,
                    color: isLoading
                        ? WellxColors.textTertiary
                        : WellxColors.deepPurple,
                  ),
                ),
              )),
              const SizedBox(width: WellxSpacing.sm),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: WellxColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: WellxColors.border),
                  ),
                  child: TextField(
                    key: const Key('chat_input_field'),
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !isLoading,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask Dr. Layla...',
                      hintStyle: WellxTypography.bodyText.copyWith(
                        color: WellxColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: WellxTypography.bodyText.copyWith(
                      color: WellxColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: WellxSpacing.sm),
              Semantics(
                button: true,
                label: 'Send message',
                enabled: !isLoading,
                child: GestureDetector(
                key: const Key('chat_send_button'),
                onTap: isLoading ? null : _sendMessage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isLoading ? null : WellxColors.primaryGradient,
                    color: isLoading ? WellxColors.border : null,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: isLoading
                        ? WellxColors.textTertiary
                        : Colors.white,
                    size: 20,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing Dots Animation
// ---------------------------------------------------------------------------

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });
    _anims = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();

    // Stagger starts
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WellxColors.deepPurple
                    .withValues(alpha: 0.25 + 0.6 * _anims[i].value),
              ),
            );
          },
        );
      }),
    );
  }
}
