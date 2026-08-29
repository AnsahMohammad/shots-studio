/// JSON utility functions for parsing and fixing JSON responses
class JsonUtils {
  /// Count structural brackets/braces, skipping characters inside JSON strings.
  /// Returns a map with counts of open/close brackets and braces.
  static Map<String, int> _countStructuralBrackets(String jsonString) {
    int openBrackets = 0;
    int closeBrackets = 0;
    int openBraces = 0;
    int closeBraces = 0;
    bool inString = false;

    for (int i = 0; i < jsonString.length; i++) {
      final char = jsonString[i];

      // Handle string boundaries — skip escaped quotes (e.g. \")
      if (char == '"' && (i == 0 || jsonString[i - 1] != '\\')) {
        inString = !inString;
        continue;
      }

      // Don't count brackets/braces that are inside string values
      if (inString) continue;

      switch (char) {
        case '[':
          openBrackets++;
          break;
        case ']':
          closeBrackets++;
          break;
        case '{':
          openBraces++;
          break;
        case '}':
          closeBraces++;
          break;
      }
    }

    return {
      'openBrackets': openBrackets,
      'closeBrackets': closeBrackets,
      'openBraces': openBraces,
      'closeBraces': closeBraces,
    };
  }

  /// Check if JSON string appears to be complete by matching brackets and braces
  static bool isCompleteJson(String jsonString) {
    if (jsonString.trim().isEmpty) return false;

    final counts = _countStructuralBrackets(jsonString);
    return counts['openBrackets']! == counts['closeBrackets']! &&
        counts['openBraces']! == counts['closeBraces']!;
  }

  /// Attempt to fix incomplete JSON by adding missing brackets and braces
  static String attemptJsonFix(String jsonString) {
    String fixed = jsonString.trim();

    final counts = _countStructuralBrackets(fixed);

    // Add missing closing braces
    int missingBraces = counts['openBraces']! - counts['closeBraces']!;
    for (int i = 0; i < missingBraces; i++) {
      fixed += '}';
    }

    // Add missing closing brackets
    int missingBrackets = counts['openBrackets']! - counts['closeBrackets']!;
    for (int i = 0; i < missingBrackets; i++) {
      fixed += ']';
    }

    return fixed;
  }

  /// Clean response text by removing thinking tags (<think>...</think>) and markdown code fences
  static String cleanMarkdownCodeFences(String responseText) {
    String cleaned = responseText.trim();

    // Strip <think>...</think> reasoning blocks if present (from reasoning/thinking models)
    cleaned = cleaned.replaceAll(RegExp(r'<think>[\s\S]*?<\/think>', caseSensitive: false), '').trim();

    // If there is a markdown code block ```json ... ``` inside, extract its content
    final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false).firstMatch(cleaned);
    if (codeBlockMatch != null && codeBlockMatch.group(1) != null) {
      cleaned = codeBlockMatch.group(1)!.trim();
    } else {
      // Remove leading code fences
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }

      // Remove trailing code fences
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    }

    return cleaned.trim();
  }
}
