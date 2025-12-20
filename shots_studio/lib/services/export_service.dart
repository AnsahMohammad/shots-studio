import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

/// Result of an export operation
class ExportResult {
  final bool success;
  final String message;
  final int exportedCount;
  final int failedCount;

  ExportResult({
    required this.success,
    required this.message,
    this.exportedCount = 0,
    this.failedCount = 0,
  });
}

/// Service for exporting collection screenshots as ZIP or individual files
class ExportService {
  /// Export screenshots as a ZIP file and share via the system share sheet
  static Future<ExportResult> exportAsZip({
    required List<Screenshot> screenshots,
    required String collectionName,
  }) async {
    if (screenshots.isEmpty) {
      return ExportResult(
        success: false,
        message: 'No screenshots to export',
      );
    }

    try {
      final archive = Archive();
      int addedCount = 0;
      int failedCount = 0;

      for (final screenshot in screenshots) {
        if (screenshot.path == null) {
          failedCount++;
          continue;
        }

        final file = File(screenshot.path!);
        if (!await file.exists()) {
          failedCount++;
          continue;
        }

        try {
          final bytes = await file.readAsBytes();
          final fileName = screenshot.path!.split('/').last;
          
          // Add file to archive
          archive.addFile(ArchiveFile(
            fileName,
            bytes.length,
            bytes,
          ));
          addedCount++;
        } catch (e) {
          print('ExportService: Failed to add file ${screenshot.path}: $e');
          failedCount++;
        }
      }

      if (addedCount == 0) {
        return ExportResult(
          success: false,
          message: 'No valid files to export',
          failedCount: failedCount,
        );
      }

      // Encode the archive as ZIP
      final zipData = ZipEncoder().encode(archive);

      // Write ZIP to temp directory
      final tempDir = await getTemporaryDirectory();
      final sanitizedName = collectionName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final zipFileName = '${sanitizedName.isEmpty ? 'collection' : sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.zip';
      final zipFile = File('${tempDir.path}/$zipFileName');
      await zipFile.writeAsBytes(zipData);

      // Share the ZIP file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(zipFile.path)],
          subject: 'Screenshots from $collectionName',
        ),
      );

      AnalyticsService().logFeatureUsed('export_collection_zip');

      return ExportResult(
        success: true,
        message: addedCount == screenshots.length
            ? '$addedCount screenshots exported successfully'
            : '$addedCount screenshots exported, $failedCount failed',
        exportedCount: addedCount,
        failedCount: failedCount,
      );
    } catch (e) {
      print('ExportService: Error creating ZIP: $e');
      return ExportResult(
        success: false,
        message: 'Failed to create ZIP: $e',
      );
    }
  }

  /// Export screenshots as individual files to a user-selected directory
  /// If [isCut] is true, files will be moved (removed from source after copy)
  static Future<ExportResult> exportAsFiles({
    required List<Screenshot> screenshots,
    required bool isCut,
    Function(String screenshotId)? onScreenshotDeleted,
  }) async {
    if (screenshots.isEmpty) {
      return ExportResult(
        success: false,
        message: 'No screenshots to export',
      );
    }

    try {
      // Let user pick a destination directory
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select destination folder',
      );

      if (selectedDirectory == null) {
        return ExportResult(
          success: false,
          message: 'Export cancelled',
        );
      }

      int exportedCount = 0;
      int failedCount = 0;

      for (final screenshot in screenshots) {
        if (screenshot.path == null) {
          failedCount++;
          continue;
        }

        final sourceFile = File(screenshot.path!);
        if (!await sourceFile.exists()) {
          failedCount++;
          continue;
        }

        try {
          final fileName = screenshot.path!.split('/').last;
          final destPath = '$selectedDirectory/$fileName';
          
          // Check if file already exists at destination
          final destFile = File(destPath);
          String finalPath = destPath;
          
          if (await destFile.exists()) {
            // Add timestamp to avoid overwriting
            final extension = fileName.contains('.') 
                ? '.${fileName.split('.').last}'
                : '';
            final baseName = fileName.contains('.')
                ? fileName.substring(0, fileName.lastIndexOf('.'))
                : fileName;
            finalPath = '$selectedDirectory/${baseName}_${DateTime.now().millisecondsSinceEpoch}$extension';
          }

          // Copy file to destination
          await sourceFile.copy(finalPath);
          exportedCount++;

          // If cut mode, delete the source file and notify
          if (isCut) {
            await sourceFile.delete();
            if (onScreenshotDeleted != null) {
              onScreenshotDeleted(screenshot.id);
            }
          }
        } catch (e) {
          print('ExportService: Failed to export file ${screenshot.path}: $e');
          failedCount++;
        }
      }

      final operation = isCut ? 'moved' : 'copied';
      AnalyticsService().logFeatureUsed(isCut ? 'export_collection_cut' : 'export_collection_copy');

      if (exportedCount == 0) {
        return ExportResult(
          success: false,
          message: 'No files could be $operation',
          failedCount: failedCount,
        );
      }

      return ExportResult(
        success: true,
        message: exportedCount == screenshots.length
            ? '$exportedCount screenshots $operation successfully'
            : '$exportedCount screenshots $operation, $failedCount failed',
        exportedCount: exportedCount,
        failedCount: failedCount,
      );
    } catch (e) {
      print('ExportService: Error exporting files: $e');
      return ExportResult(
        success: false,
        message: 'Failed to export: $e',
      );
    }
  }
}
