import 'package:mehd_ai_flutter/models/slash_command.dart';

class CommandParserService {
  static const List<String> availableCommands = ['/long', '/short', '/close', '/help'];

  /// Parses raw input into a ParsedCommand.
  /// Expected formats:
  /// /long BTC 10x
  /// /short ETH
  /// /help
  static ParsedCommand parse(String input) {
    final trimmed = input.trim();
    if (!trimmed.startsWith('/')) {
      return ParsedCommand.error(input, "Not a slash command");
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    final actionStr = parts[0].toLowerCase();

    if (!availableCommands.contains(actionStr)) {
      return ParsedCommand.error(input, "Unknown command: $actionStr. Type /help to see available commands.");
    }

    final action = actionStr.substring(1); // remove '/'

    if (action == 'help') {
      return ParsedCommand(isValid: true, rawCommand: input, action: action);
    }

    if (action == 'close') {
      if (parts.length < 2) {
        return ParsedCommand.error(input, "Usage: /close [SYMBOL]");
      }
      return ParsedCommand(
        isValid: true,
        rawCommand: input,
        action: action,
        symbol: parts[1].toUpperCase(),
      );
    }

    // Handle /long and /short
    if (parts.length < 2) {
      return ParsedCommand.error(input, "Usage: /$action [SYMBOL] [LEVERAGE(optional)]");
    }

    final symbol = parts[1].toUpperCase();
    int leverage = 1; // Default leverage

    if (parts.length >= 3) {
      final levStr = parts[2].replaceAll('x', '').replaceAll('X', '');
      final parsedLev = int.tryParse(levStr);
      if (parsedLev == null) {
        return ParsedCommand.error(input, "Invalid leverage format. Use e.g., 10x");
      }
      if (parsedLev < 1 || parsedLev > 100) {
        return ParsedCommand.error(input, "Leverage must be between 1x and 100x");
      }
      leverage = parsedLev;
    }

    return ParsedCommand(
      isValid: true,
      rawCommand: input,
      action: action,
      symbol: symbol,
      leverage: leverage,
    );
  }
}
