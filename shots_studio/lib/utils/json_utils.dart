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

  /// Clean response text by removing markdown code fences
  static String cleanMarkdownCodeFences(String responseText) {
    String cleanedResponseText = responseText.trim();

    // Remove markdown code fences if present
    if (cleanedResponseText.startsWith('```json')) {
      cleanedResponseText = cleanedResponseText.substring(7); // Remove ```json
    } else if (cleanedResponseText.startsWith('```')) {
      cleanedResponseText = cleanedResponseText.substring(3); // Remove ```
    }

    if (cleanedResponseText.endsWith('```')) {
      cleanedResponseText = cleanedResponseText.substring(
        0,
        cleanedResponseText.length - 3,
      ); // Remove ending ```
    }

    return cleanedResponseText.trim();
  }
}
