import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/logger_service.dart';

/// Service for performing OCR (Optical Character Recognition) on screenshots
/// Uses Tesseract OCR for offline text recognition
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  /// Extracts text from a screenshot using OCR
  /// Returns the extracted text or null if extraction fails
  Future<String?> extractTextFromScreenshot(Screenshot screenshot) async {
    try {
      String? imagePath;
      bool isTemporaryFile = false;

      // Handle different image sources
      if (screenshot.path != null) {
        final filePath = screenshot.path!; // Safe since we checked above
        final file = File(filePath);
        if (await file.exists()) {
          imagePath = filePath;
        } else {
          throw Exception('Screenshot file not found');
        }
      } else if (screenshot.bytes != null) {
        // Create temporary file from bytes
        final bytes = screenshot.bytes!; // Safe since we checked above
        imagePath = await _createTempFileFromBytes(bytes);
        isTemporaryFile = true;
      } else {
        throw Exception('No image data available');
      }

      // Perform OCR using Tesseract
      final config = OCRConfig(language: 'eng', engine: OCREngine.tesseract);

      final extractedText = await TesseractOcr.extractText(
        imagePath,
        config: config,
      );

      // Clean up temporary file if created
      if (isTemporaryFile) {
        await _cleanupTempFile(imagePath);
      }

      return extractedText.trim().isEmpty ? null : extractedText.trim();
    } catch (e) {
      LoggerService.error('OCR extraction error', e);
      return null;
    }
  }

  /// Creates a temporary file from bytes for OCR processing
  Future<String> _createTempFileFromBytes(Uint8List bytes) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(bytes);
    return tempFile.path;
  }

  /// Cleans up temporary files created during OCR processing
  Future<void> _cleanupTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      LoggerService.error('Error cleaning up temp file', e);
    }
  }

  /// Copies text to clipboard
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Extracts text from screenshot and copies to clipboard
  /// Returns the extracted text if successful, null otherwise
  Future<String?> extractTextAndCopyToClipboard(Screenshot screenshot) async {
    try {
      final extractedText = await extractTextFromScreenshot(screenshot);

      if (extractedText != null && extractedText.isNotEmpty) {
        await copyToClipboard(extractedText);
        return extractedText;
      }

      return null;
    } catch (e) {
      LoggerService.error('Error extracting text and copying to clipboard', e);
      return null;
    }
  }

  /// Checks if OCR is available on the current platform
  bool isOCRAvailable() {
    // Tesseract OCR is available on Android and iOS
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Gets supported languages for OCR
  /// This is a basic implementation - in a real app, you might want to
  /// check which language packs are actually installed
  List<String> getSupportedLanguages() {
    return ['eng']; // English
  }
}
