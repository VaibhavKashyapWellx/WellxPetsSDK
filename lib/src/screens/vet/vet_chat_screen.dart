import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final hasMessages = chatState.messages.isNotEmpty || chatState.isLoading;

    return Scaffold(
      backgroundColor: WellxColors.surface,
      appBar: _buildAppBar(pet?.name),
      body: Stack(
        children: [
          // Main content area
          GestureDetector(
            onTap: () => _focusNode.unfocus(),
            child: hasMessages
                ? _buildMessageList(chatState)
                : _buildEmptyState(),
          ),

          // Error banner
          if (chatState.errorMessage != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 200,
              child: _buildErrorBanner(chatState.errorMessage!),
            ),

          // Pending image preview
          if (_pendingImage != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 140,
              child: _buildImagePreview(),
            ),

          // Floating input bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingInputBar(chatState.isLoading),
          ),
        ],
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String? petName) {
    return AppBar(
      backgroundColor: WellxColors.surface.withValues(alpha: 0.8),
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          // AI gradient avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [WellxColors.primary, WellxColors.aiPurple],
              ),
              boxShadow: [
                BoxShadow(
                  color: WellxColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
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
                      color: WellxColors.tertiary,
                    ),
                  ),
                ],
              ),
              if (petName != null)
                Text(
                  'Reviewing $petName\'s records',
                  style: WellxTypography.captionText.copyWith(
                    color: WellxColors.onSurfaceVariant,
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
            color: WellxColors.outline,
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
                style: TextStyle(color: WellxColors.error)),
          ),
        ],
      ),
    );
  }

  // ── Empty State (Dr. Layla Intro + Suggestion Tiles) ───────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        WellxSpacing.lg,
        WellxSpacing.lg,
        WellxSpacing.lg,
        200,
      ),
      child: Column(
        children: [
          const SizedBox(height: WellxSpacing.xl),
          // Dr. Layla Intro
          _buildDrLaylaIntro(),
          const SizedBox(height: WellxSpacing.xxl),
          // Bento Grid Suggestion Tiles
          _buildSuggestionTiles(),
        ],
      ),
    );
  }

  Widget _buildDrLaylaIntro() {
    return Column(
      children: [
        // Avatar with gradient ring and green dot
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [WellxColors.primary, WellxColors.aiPurple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: WellxColors.primary.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.surfaceContainerHigh,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: WellxColors.primary,
                  size: 38,
                ),
              ),
            ),
            // Green dot indicator
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.tertiary,
                  border: Border.all(color: WellxColors.surfaceContainerLowest, width: 2),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: WellxSpacing.lg),
        // "Dr. Layla" heading
        Text(
          'Dr. Layla',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: WellxColors.onSurface,
          ),
        ),
        const SizedBox(height: WellxSpacing.sm),
        // Subtitle
        SizedBox(
          width: 280,
          child: Text(
            'Your AI Pet Wellness Partner. Ask me anything about your pet\'s health.',
            textAlign: TextAlign.center,
            style: WellxTypography.captionText.copyWith(
              color: WellxColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionTiles() {
    return Column(
      children: [
        // Full-width Symptom Check tile
        _buildSuggestionTile(
          icon: Icons.medical_services_rounded,
          iconColor: WellxColors.error,
          title: 'Symptom Check',
          subtitle: "Describe what's happening with your pet.",
          onTap: () => _sendChip("My pet has a symptom I'd like to check"),
          isFullWidth: true,
        ),
        const SizedBox(height: WellxSpacing.md),
        // Half-width row: Diet Advice + Medication
        Row(
          children: [
            Expanded(
              child: _buildSuggestionTile(
                icon: Icons.restaurant_rounded,
                iconColor: WellxColors.tertiary,
                title: 'Diet Advice',
                subtitle: 'Nutrition & treats.',
                onTap: () => _sendChip('I need diet advice for my pet'),
              ),
            ),
            const SizedBox(width: WellxSpacing.md),
            Expanded(
              child: _buildSuggestionTile(
                icon: Icons.medication_rounded,
                iconColor: WellxColors.primary,
                title: 'Medication',
                subtitle: 'Dosage & safety.',
                onTap: () => _sendChip('I have a medication question'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(WellxSpacing.lg + 4),
        decoration: BoxDecoration(
          color: WellxColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: WellxColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: iconColor, size: 24),
                        const SizedBox(height: WellxSpacing.md),
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: WellxColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: WellxSpacing.xs),
                        Text(
                          subtitle,
                          style: WellxTypography.captionText.copyWith(
                            color: WellxColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: WellxColors.outlineVariant,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(height: WellxSpacing.md),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: WellxColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: WellxSpacing.xs),
                  Text(
                    subtitle,
                    style: WellxTypography.captionText.copyWith(
                      color: WellxColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Message List ─────────────────────────────────────────────────────────

  Widget _buildMessageList(VetChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        WellxSpacing.lg,
        WellxSpacing.sm,
        WellxSpacing.lg,
        200, // padding for floating input bar + nav bar
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

    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.lg),
      child: isUser ? _buildUserBubble(message) : _buildAiBubble(message),
    );
  }

  Widget _buildAiBubble(ChatMessage message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // AI avatar: small gradient circle with smart_toy icon
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WellxColors.primary, WellxColors.aiPurple],
            ),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: WellxSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.all(WellxSpacing.lg),
                  decoration: BoxDecoration(
                    color: WellxColors.surfaceContainerHigh,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: WellxColors.onSurface.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: WellxTypography.bodyText.copyWith(
                        color: WellxColors.onSurface,
                        height: 1.5,
                      ),
                      strong: WellxTypography.bodyText.copyWith(
                        color: WellxColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: WellxTypography.bodyText.copyWith(
                        color: WellxColors.onSurfaceVariant,
                      ),
                      h1: WellxTypography.heading.copyWith(fontSize: 18),
                      h2: WellxTypography.heading.copyWith(fontSize: 16),
                      h3: WellxTypography.heading.copyWith(fontSize: 14),
                      code: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: WellxColors.primary,
                        backgroundColor: WellxColors.surfaceContainerLow,
                      ),
                      blockquotePadding: const EdgeInsets.only(left: 12),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: WellxColors.primary.withValues(alpha: 0.3),
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
      ],
    );
  }

  Widget _buildUserBubble(ChatMessage message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
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
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.all(WellxSpacing.lg),
                  decoration: BoxDecoration(
                    color: WellxColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: WellxColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: WellxTypography.bodyText.copyWith(
                      color: WellxColors.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: WellxSpacing.sm),
        // User avatar: small primary circle with person icon
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: WellxColors.primary,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
      ],
    );
  }

  // ── Typing Indicator ─────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [WellxColors.primary, WellxColors.aiPurple],
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: WellxSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: WellxColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
        color: WellxColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, size: 16, color: WellxColors.error),
          const SizedBox(width: WellxSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: WellxTypography.captionText.copyWith(
                color: WellxColors.onSurfaceVariant,
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
                color: WellxColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending image preview ───────────────────────────────────────────────

  Widget _buildImagePreview() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
      padding: const EdgeInsets.symmetric(
          horizontal: WellxSpacing.md, vertical: WellxSpacing.sm),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: WellxColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
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
                      color: WellxColors.onSurface,
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
              color: WellxColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating Input Bar ─────────────────────────────────────────────────

  Widget _buildFloatingInputBar(bool isLoading) {
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick suggestion chip
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.only(
                left: WellxSpacing.lg,
                right: WellxSpacing.lg,
                bottom: WellxSpacing.sm,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _sendChip('Tell me about flea & tick prevention'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: WellxColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: WellxColors.onSurface.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: WellxColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Flea & Tick',
                            style: WellxTypography.chipText.copyWith(
                              color: WellxColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerLowest.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: WellxColors.onSurface.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WellxSpacing.xs,
                  vertical: WellxSpacing.xs,
                ),
                child: Row(
                  children: [
                    // Camera / attach button
                    GestureDetector(
                      onTap: isLoading ? null : _pickImage,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_circle_rounded,
                          size: 24,
                          color: isLoading
                              ? WellxColors.outlineVariant
                              : WellxColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !isLoading,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: WellxTypography.bodyText.copyWith(
                            color: WellxColors.outlineVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                        style: WellxTypography.bodyText.copyWith(
                          color: WellxColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: WellxSpacing.xs),
                    // Send button
                    GestureDetector(
                      onTap: isLoading ? null : _sendMessage,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isLoading
                              ? null
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    WellxColors.primary,
                                    WellxColors.aiPurple,
                                  ],
                                ),
                          color: isLoading
                              ? WellxColors.surfaceContainerHigh
                              : null,
                          boxShadow: isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color: WellxColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: isLoading
                              ? WellxColors.outlineVariant
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom safe area spacer
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 8,
          ),
        ],
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
          builder: (_, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WellxColors.primary
                    .withValues(alpha: 0.25 + 0.6 * _anims[i].value),
              ),
            );
          },
        );
      }),
    );
  }
}
