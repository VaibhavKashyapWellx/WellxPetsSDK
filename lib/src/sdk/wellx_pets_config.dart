/// Configuration for the WellxPetsSDK.
class WellxPetsConfig {
  /// Supabase project URL (e.g., https://xxxx.supabase.co)
  final String supabaseUrl;

  /// Supabase anonymous/public key
  final String supabaseAnonKey;

  /// Anthropic API key for Claude AI features (vet chat, OCR)
  final String anthropicApiKey;

  /// Claude model to use for complex tasks (default: claude-sonnet-4-6)
  final String claudeModel;

  /// Claude model for fast/simple tasks
  final String claudeModelFast;

  /// ElevenLabs agent ID for voice assistant (optional)
  final String? elevenlabsAgentId;

  /// ElevenLabs API key (optional)
  final String? elevenlabsApiKey;

  /// Distribution API base URL for insurance features (optional)
  final String? distributionBaseUrl;

  const WellxPetsConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.anthropicApiKey,
    this.claudeModel = 'claude-sonnet-4-6',
    this.claudeModelFast = 'claude-sonnet-4-6',
    this.elevenlabsAgentId,
    this.elevenlabsApiKey,
    this.distributionBaseUrl,
  });
}
