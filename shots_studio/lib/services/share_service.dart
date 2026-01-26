import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_utils;
import 'package:share_handler/share_handler.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/file_watcher_service.dart';
import 'package:shots_studio/services/logger_service.dart';
import 'package:uuid/uuid.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  StreamSubscription? _intentDataStreamSubscription;
  final Uuid _uuid = const Uuid();

  final StreamController<Screenshot> _screenshotController =
      StreamController<Screenshot>.broadcast();
  Stream<Screenshot> get screenshotStream => _screenshotController.stream;

  /// Initialize the share service handler
  Future<void> initialize() async {
    LoggerService.log('ShareService: Initializing...');

    // 1. Handle the initial intent (if app was closed)
    _checkInitialMedia();

    // 2. Listen for new intents (while app is running)
    _intentDataStreamSubscription = ShareHandlerPlatform
        .instance
        .sharedMediaStream
        .listen(
          (SharedMedia media) {
            LoggerService.log('ShareService: Received new shared media');
            _processSharedMedia(media);
          },
          onError: (err) {
            LoggerService.error(
              'ShareService: Error in shared media stream',
              err,
            );
          },
        );
  }

  Future<void> _checkInitialMedia() async {
    try {
      final initialMedia =
          await ShareHandlerPlatform.instance.getInitialSharedMedia();
      if (initialMedia != null) {
        LoggerService.log('ShareService: Found initial shared media');
        _processSharedMedia(initialMedia);
      }
    } catch (e) {
      LoggerService.error('ShareService: Error checking initial media', e);
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _screenshotController.close();
  }

  /// Process the shared media payload
  Future<void> _processSharedMedia(SharedMedia media) async {
    try {
      // Check for attachments (Images)
      if (media.attachments != null && media.attachments!.isNotEmpty) {
        final attachment = media.attachments!.first;
        if (attachment == null || attachment.path.isEmpty) return;

        final originalPath = attachment.path;
        LoggerService.log(
          'ShareService: Processing shared image: $originalPath',
        );

        // Copy the file to our local storage to persist it
        final appDir = await getApplicationDocumentsDirectory();
        final sharedImagesDir = Directory('${appDir.path}/shared_images');

        if (!await sharedImagesDir.exists()) {
          await sharedImagesDir.create(recursive: true);
        }

        // Generate a unique filename to avoid collisions and allow duplicates
        final extension = path_utils.extension(originalPath);
        final fileName = 'shared_${_uuid.v4()}$extension';
        final newPath = '${sharedImagesDir.path}/$fileName';

        try {
          await File(originalPath).copy(newPath);
          LoggerService.log('ShareService: Persisted shared image to $newPath');
        } catch (e) {
          LoggerService.error(
            'ShareService: Failed to copy shared image. Using original path.',
            e,
          );
          // Fallback to original path if copy fails (though persistence might fail)
        }

        // Use the new path if copy succeeded, otherwise original
        final effectivePath =
            await File(newPath).exists() ? newPath : originalPath;

        // Prevent FileWatcher from re-processing this file if it monitors this dir
        FileWatcherService().addProcessedFile(effectivePath);

        // Extract text/URL content for notes if available
        String? notes;
        if (media.content != null && media.content!.trim().isNotEmpty) {
          notes = media.content;
          LoggerService.log('ShareService: Found attached text/URL: $notes');
        }

        // Create Screenshot Object
        final screenshot = await Screenshot.fromFilePath(
          id: _uuid.v4(),
          filePath: effectivePath,
          // We don't mark it as AI processed yet, user might want to edit
        );

        // Add the notes if we found them
        if (notes != null) {
          screenshot.notes = notes;
        }

        // Emit the screenshot for the UI to handle
        _screenshotController.add(screenshot);
      } else {
        LoggerService.log(
          'ShareService: Received share but no image attachments found.',
        );
      }
    } catch (e) {
      LoggerService.error('ShareService: Error processing shared media', e);
    }
  }
}
