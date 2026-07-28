/// LiveKit Configuration for Eco-Giants Live AI Tutor
/// These values are provided by your LiveKit cloud project.
class LiveKitConfig {
  static const String wsUrl =
      'wss://eco-giants-l8flnoop.livekit.cloud';
  static const String apiKey = 'APIbTNp58iUneWh';
  static const String apiSecret =
      'yDau9pZ3QPKTH3QUWbSZNdWW4CwKBUDlD4Vaf8Rer2R';
}

/// NVIDIA API Configuration for LLM chat
class NvidiaConfig {
  static const String apiKey =
      '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';
  static const String baseUrl = 'https://integrate.api.nvidia.com/v1';
  static const String model = 'meta/llama-3.1-8b-instruct';

  /// Max tokens per completion
  static const int maxTokens = 1024;

  /// Temperature for generation (0.0 - 1.0)
  static const double temperature = 0.7;
}
