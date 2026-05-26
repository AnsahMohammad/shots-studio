import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PrefilterTokenizer {
  static PrefilterTokenizer? _instance;
  static Future<PrefilterTokenizer> getInstance() async {
    _instance ??= await _load();
    return _instance!;
  }

  final Map<String,int> _vocab;
  final List<List<int>> _merges;
  final int _clsId, _sepId, _unkId, _padId;

  PrefilterTokenizer._({required Map<String,int> vocab, required List<List<int>> merges,
      required int clsId, required int sepId, required int unkId, required int padId})
      : _vocab=vocab, _merges=merges, _clsId=clsId, _sepId=sepId, _unkId=unkId, _padId=padId;

  static Future<PrefilterTokenizer> _load() async {
    final directory = await getApplicationSupportDirectory();
    final tokenizerPath = '${directory.path}/gliner_tokenizer.json';
    
    if (!await File(tokenizerPath).exists()) {
      throw Exception('Tokenizer file not found at $tokenizerPath. Please download the prefilter model first.');
    }

    final raw = await File(tokenizerPath).readAsString();
    final json = jsonDecode(raw) as Map<String,dynamic>;
    final vocab = (json['model']['vocab'] as Map<String,dynamic>)
        .map((k,v) => MapEntry(k, v as int));
    final merges = (json['model']['merges'] as List).map((m) {
      final p = (m as String).split(' ');
      return [vocab[p[0]] ?? 0, vocab[p[1]] ?? 0];
    }).toList();
    int findId(String c) {
      final t = (json['added_tokens'] as List)
          .firstWhere((t) => t['content']==c, orElse: () => {'id':0});
      return (t as Map)['id'] as int;
    }
    return PrefilterTokenizer._(vocab:vocab, merges:merges,
        clsId:findId('[CLS]'), sepId:findId('[SEP]'),
        unkId:vocab['[UNK]'] ?? 1, padId:vocab['[PAD]'] ?? 0);
  }

  Map<String,List<int>> encode(String text, {int maxLength=512}) {
    final words = text.toLowerCase().split(RegExp(r'[\s\p{P}]+')).where((w)=>w.isNotEmpty);
    final ids   = <int>[_clsId];
    for (final w in words) { ids.addAll(_bpe(w)); if (ids.length >= maxLength-1) break; }
    ids.add(_sepId);
    final trunc  = ids.length > maxLength ? ids.sublist(0, maxLength) : ids;
    final padded = List<int>.from(trunc);
    final attn   = List<int>.filled(maxLength, 0);
    for (int i = 0; i < trunc.length; i++) attn[i] = 1;
    while (padded.length < maxLength) padded.add(_padId);
    return {'input_ids':padded, 'attention_mask':attn};
  }

  List<int> _bpe(String word) {
    if (word.isEmpty) return [];
    var chars = ['▁${word[0]}', ...word.substring(1).split('')];
    bool changed = true;
    while (changed && chars.length > 1) {
      changed = false; int bestIdx=-1, bestRank=_merges.length+1;
      for (int i=0; i<chars.length-1; i++) {
        final a=_vocab[chars[i]] ?? -1, b=_vocab[chars[i+1]] ?? -1;
        if (a<0||b<0) continue;
        final rank = _merges.indexWhere((m)=>m[0]==a&&m[1]==b);
        if (rank>=0 && rank<bestRank) { bestRank=rank; bestIdx=i; }
      }
      if (bestIdx>=0) { chars[bestIdx]+=chars[bestIdx+1]; chars.removeAt(bestIdx+1); changed=true; }
    }
    return chars.map((c)=>_vocab[c] ?? _unkId).toList();
  }
}
