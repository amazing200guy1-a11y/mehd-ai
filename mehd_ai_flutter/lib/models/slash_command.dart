class ParsedCommand {
  final bool isValid;
  final String rawCommand;
  final String action; // long, short, close, help
  final String? symbol;
  final int? leverage;
  final String? errorMessage;

  ParsedCommand({
    required this.isValid,
    required this.rawCommand,
    required this.action,
    this.symbol,
    this.leverage,
    this.errorMessage,
  });

  factory ParsedCommand.error(String raw, String message) {
    return ParsedCommand(
      isValid: false,
      rawCommand: raw,
      action: 'unknown',
      errorMessage: message,
    );
  }
}
