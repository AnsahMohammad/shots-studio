// AI Error Handling Utilities
import 'package:flutter/material.dart';

typedef ShowMessageCallback =
    void Function({
      required String message,
      Color? backgroundColor,
      Duration? duration,
    });

class AIErrorHandler {
  /// Handles API response errors and provides appropriate user feedback
  static AIErrorResult handleResponseError(
    Map<String, dynamic> response, {
    required ShowMessageCallback? showMessage,
    required bool Function() isCancelled,
    required void Function() cancelProcessing,
    required bool apiKeyErrorShown,
    required bool processingTerminated,
    required int networkErrorCount,
    required void Function(bool) setApiKeyErrorShown,
    required void Function(bool) setProcessingTerminated,
    required void Function(int) setNetworkErrorCount,
  }) {
    // Check for quota exceeded error (429 or text match)
    if (_isQuotaExceededError(response)) {
      cancelProcessing();
      setProcessingTerminated(true);

      showMessage?.call(
        message: 'API quota exceeded. Please change your AI model in settings.',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      return AIErrorResult(
        shouldTerminate: true,
        errorType: AIErrorType.quotaExceeded,
      );
    } else if (response['error'] != null &&
        response['error'].toString().contains('API key not valid')) {
      // Only show the error message once and terminate processing
      if (!apiKeyErrorShown) {
        setApiKeyErrorShown(true);
        cancelProcessing();
        setProcessingTerminated(true);

        showMessage?.call(
          message:
              'Invalid API key provided. AI processing has been terminated.',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
      }
      return AIErrorResult(
        shouldTerminate: true,
        errorType: AIErrorType.invalidApiKey,
      );
    } else if (response['error'] != null &&
        response['error'].toString().contains('Network error')) {
      // Increment network error count
      final newCount = networkErrorCount + 1;
      setNetworkErrorCount(newCount);

      // If we get repeated network errors or the app was closed and reopened,
      // we should cancel all AI processing
      if (newCount >= 2 || processingTerminated) {
        // Cancel all AI processing
        cancelProcessing();
        setProcessingTerminated(true);

        showMessage?.call(
          message:
              'Network issues detected. AI processing has been terminated.',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        );

        return AIErrorResult(
          shouldTerminate: true,
          errorType: AIErrorType.networkError,
        );
      } else {
        showMessage?.call(
          message:
              'Network issue detected. Please check your internet connection and try again.',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        );

        return AIErrorResult(
          shouldTerminate: false,
          errorType: AIErrorType.networkError,
        );
      }
    } else {
      showMessage?.call(
        message:
            'No data found in response or error occurred: ${response['error']}',
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      );

      return AIErrorResult(
        shouldTerminate: false,
        errorType: AIErrorType.genericError,
      );
    }
  }

  /// Checks if an error indicates that processing should be terminated
  static bool shouldTerminateProcessing(String errorMessage) {
    return errorMessage.contains('API key not valid') ||
        errorMessage.contains('Network error') ||
        errorMessage.contains('exceeded your current quota');
  }

  /// Checks if a response indicates a quota exceeded error.
  /// Looks for statusCode 429 or error text containing the quota message.
  static bool isQuotaExceededError(Map<String, dynamic> response) {
    return _isQuotaExceededError(response);
  }

  static bool _isQuotaExceededError(Map<String, dynamic> response) {
    final statusCode = response['statusCode'];
    final error = response['error']?.toString() ?? '';
    return statusCode == 429 || error.contains('exceeded your current quota');
  }

  /// Gets appropriate error message for different error types
  static String getErrorMessage(AIErrorType errorType) {
    switch (errorType) {
      case AIErrorType.invalidApiKey:
        return 'Invalid API key provided. AI processing has been terminated.';
      case AIErrorType.networkError:
        return 'Network issues detected. AI processing has been terminated.';
      case AIErrorType.quotaExceeded:
        return 'API quota exceeded. Please change your AI model in settings.';
      case AIErrorType.timeout:
        return 'Request timed out. Please try again.';
      case AIErrorType.genericError:
        return 'An error occurred during AI processing.';
    }
  }
}

enum AIErrorType {
  invalidApiKey,
  networkError,
  quotaExceeded,
  timeout,
  genericError,
}

class AIErrorResult {
  final bool shouldTerminate;
  final AIErrorType errorType;
  final String? customMessage;

  const AIErrorResult({
    required this.shouldTerminate,
    required this.errorType,
    this.customMessage,
  });
}
