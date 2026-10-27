import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:shots_studio/models/prefilter_result.dart';
import 'package:shots_studio/services/prefilter_tokenizer.dart';
import 'package:shots_studio/services/logger_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PrefilterMlService {
  static const double _threshold = 0.5;
  static PrefilterMlService? _instance;

  // Lazy singleton — ONNX session loaded once, reused for every screenshot
  static Future<PrefilterMlService> getInstance() async {
    _instance ??= await _init();
    return _instance!;
  }

  final OrtSession _session;
  final PrefilterTokenizer _tokenizer;

  PrefilterMlService._({required OrtSession session, required PrefilterTokenizer tokenizer})
      : _session=session, _tokenizer=tokenizer;

  static Future<PrefilterMlService> _init() async {
    OrtEnv.instance.init();
    final directory = await getApplicationSupportDirectory();
    final modelPath = '${directory.path}/gliner_pii_small.onnx';
    
    if (!await File(modelPath).exists()) {
      throw Exception('Prefilter model not found at $modelPath. Please download it first.');
    }

    // Load from file (more memory efficient than buffer)
    final session = OrtSession.fromFile(File(modelPath),
        OrtSessionOptions()..setInterOpNumThreads(1)..setIntraOpNumThreads(2));
    
    final tokenizer = await PrefilterTokenizer.getInstance();
    LoggerService.log('[PrefilterML] GLiNER session loaded from local storage');
    return PrefilterMlService._(session:session, tokenizer:tokenizer);
  }

  Future<PrefilterResult> detect(String text) async {
    if (text.trim().length < 10) return const PrefilterResult.clean();
    try {
      const seqLen=512, entityLen=8;
      final types = PiiEntityTypes.all;
      final n = types.length;

      final enc  = _tokenizer.encode(text, maxLength:seqLen);
      final eIds = List<int>.filled(n*entityLen, 0);
      final eMsk = List<int>.filled(n*entityLen, 0);
      for (int i=0; i<n; i++) {
        final e = _tokenizer.encode(types[i], maxLength:entityLen);
        for (int j=0; j<entityLen; j++) {
          eIds[i*entityLen+j] = j < e['input_ids']!.length      ? e['input_ids']![j]      : 0;
          eMsk[i*entityLen+j] = j < e['attention_mask']!.length ? e['attention_mask']![j] : 0;
        }
      }
      final inputs = {
        'input_ids':             OrtValueTensor.createTensorWithDataList(enc['input_ids']!,      [1,seqLen]),
        'attention_mask':        OrtValueTensor.createTensorWithDataList(enc['attention_mask']!, [1,seqLen]),
        'entity_input_ids':      OrtValueTensor.createTensorWithDataList(eIds, [1,n,entityLen]),
        'entity_attention_mask': OrtValueTensor.createTensorWithDataList(eMsk, [1,n,entityLen]),
      };
      final outputs = await _session.runAsync(OrtRunOptions(), inputs);
      if (outputs == null || outputs.isEmpty) {
        for (final v in inputs.values) v.release();
        return const PrefilterResult.clean();
      }

      final logits = (outputs[0]!.value as List).cast<List>()
          .map((a)=>a.cast<List>().map((b)=>b.cast<List>()
          .map((c)=>c.cast<double>().toList()).toList()).toList()).toList();

      final hits = <PiiEntity>[];
      for (int ei=0; ei<n; ei++) {
        if (ei >= logits[0].length) break;
        final eLgt = logits[0][ei];
        for (int s=1; s<seqLen-1; s++) {
          if (s >= eLgt.length) break;
          for (int e=s; e<math.min(s+20, seqLen-1); e++) {
            if (e >= eLgt[s].length) break;
            final score = _sigmoid(eLgt[s][e]);
            if (score >= _threshold)
              hits.add(PiiEntity(type:types[ei], text:'', score:score));
          }
        }
      }
      for (final v in inputs.values) v.release();
      if (outputs != null) {
        for (final o in outputs) o?.release();
      }

      if (hits.isEmpty) return const PrefilterResult.clean();
      hits.sort((a,b) => b.score.compareTo(a.score));
      final top = hits.first;
      final reason = '${top.type[0].toUpperCase()}${top.type.substring(1)} detected';
      LoggerService.log('[PrefilterML] ${top.type} (${(top.score*100).toStringAsFixed(1)}%)');
      return PrefilterResult.sensitive(reason:reason, entities:hits);
    } catch (e, st) {
      LoggerService.error('[PrefilterML] Error', e, st);
      return const PrefilterResult.clean(); // always allow on error — never crash the pipeline
    }
  }

  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));
  void dispose() { _session.release(); OrtEnv.instance.release(); }
}
