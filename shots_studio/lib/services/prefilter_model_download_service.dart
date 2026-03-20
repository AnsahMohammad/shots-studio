import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

enum PrefilterDownloadStatus { idle, downloading, completed, error }

class PrefilterDownloadProgress {
  final double progress;
  final PrefilterDownloadStatus status;
  final String? error;

  const PrefilterDownloadProgress({
    required this.progress,
    required this.status,
    this.error,
  });
}

class PrefilterModelDownloadService extends ChangeNotifier {
  static final PrefilterModelDownloadService _instance =
      PrefilterModelDownloadService._internal();
  factory PrefilterModelDownloadService() => _instance;
  PrefilterModelDownloadService._internal();

  // URLs for the model and tokenizer from Hugging Face
  static const String _modelUrl = 
      'https://huggingface.co/onnx-community/gliner_small-v2.1/resolve/main/onnx/model.onnx';
  static const String _tokenizerUrl = 
      'https://huggingface.co/onnx-community/gliner_small-v2.1/resolve/main/tokenizer.json';

  PrefilterDownloadProgress _progress = const PrefilterDownloadProgress(
    progress: 0.0,
    status: PrefilterDownloadStatus.idle,
  );

  PrefilterDownloadProgress get progress => _progress;
  bool get isDownloading => _progress.status == PrefilterDownloadStatus.downloading;
  bool get isCompleted => _progress.status == PrefilterDownloadStatus.completed;

  Future<bool> isModelDownloaded() async {
    final directory = await getApplicationSupportDirectory();
    final modelFile = File('${directory.path}/gliner_pii_small.onnx');
    final tokenizerFile = File('${directory.path}/gliner_tokenizer.json');
    return await modelFile.exists() && await tokenizerFile.exists();
  }

  Future<void> startDownload() async {
    if (isDownloading) return;

    _updateProgress(PrefilterDownloadStatus.downloading, 0.0);
    AnalyticsService().logFeatureUsed('prefilter_model_download_started');

    try {
      final directory = await getApplicationSupportDirectory();
      
      // Download Tokenizer (small)
      await _downloadFile(_tokenizerUrl, '${directory.path}/gliner_tokenizer.json');
      _updateProgress(PrefilterDownloadStatus.downloading, 0.1);

      // Download Model (large)
      await _downloadFile(_modelUrl, '${directory.path}/gliner_pii_small.onnx', (p) {
        _updateProgress(PrefilterDownloadStatus.downloading, 0.1 + (p * 0.9));
      });

      _updateProgress(PrefilterDownloadStatus.completed, 1.0);
      AnalyticsService().logFeatureUsed('prefilter_model_download_completed');
    } catch (e) {
      _updateProgress(PrefilterDownloadStatus.error, 0.0, error: e.toString());
      AnalyticsService().logFeatureUsed('prefilter_model_download_failed');
    }
  }

  Future<void> _downloadFile(String url, String savePath, [Function(double)? onProgress]) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final file = File(savePath);
      final sink = file.openWrite();
      
      final totalBytes = response.contentLength ?? 1;
      int downloadedBytes = 0;

      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        onProgress?.call(downloadedBytes / totalBytes);
      }

      await sink.close();
    } finally {
      client.close();
    }
  }

  void _updateProgress(PrefilterDownloadStatus status, double progress, {String? error}) {
    _progress = PrefilterDownloadProgress(
      progress: progress,
      status: status,
      error: error,
    );
    notifyListeners();
  }
}
