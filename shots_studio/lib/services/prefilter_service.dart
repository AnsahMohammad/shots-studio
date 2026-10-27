import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/models/prefilter_result.dart';
import 'package:shots_studio/services/prefilter_ml_service.dart';

const String kPrefilterModeKey = 'prefilter_mode';

class PrefilterService {

  // High-precision patterns with structural prefixes — false positives near-impossible
  static final _googleKey  = RegExp(r'\bAIza[0-9A-Za-z\-_]{35}\b');
  static final _openAiKey  = RegExp(r'\bsk-[a-zA-Z0-9]{32,64}\b');
  static final _anthropic  = RegExp(r'\bsk-ant-[a-zA-Z0-9\-_]{30,}\b');
  static final _awsKey     = RegExp(r'\b(?:AKIA|ASIA|AROA|ANPA)[A-Z0-9]{16}\b');
  static final _githubPat  = RegExp(r'\bghp_[A-Za-z0-9]{36}\b');
  static final _stripeKey  = RegExp(r'\b(?:sk|pk)_(?:live|test)_[A-Za-z0-9]{24,}\b');
  static final _pemKey     = RegExp(r'-----BEGIN');
  static final _cardStrict = RegExp(r'\b(?:\d{4}[ \-]){3}\d{1,4}\b');
  static final _cardExclude = RegExp(
    r'\b(order|serial|imei|ref|invoice|product|sku|barcode|no\.)\s*[:\-]?\s*\d{13,19}\b',
    caseSensitive: false,
  );

  static Future<String> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kPrefilterModeKey) ?? 'none';
  }

  static Future<void> setMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefilterModeKey, mode);
  }

  // Call getMode() once and pass [mode] to avoid repeated async reads in a batch
  Future<PrefilterResult> check(String? ocrText, String mode) async {
    if (mode == 'none') return const PrefilterResult.clean();
    if (ocrText == null || ocrText.trim().length < 10) return const PrefilterResult.clean();

    final regexResult = _checkRegex(ocrText);
    if (regexResult.isSensitive) return regexResult;

    if (mode == 'deep') {
      try {
        final ml = await PrefilterMlService.getInstance();
        return await ml.detect(ocrText);
      } catch (e) {
        // Fallback to clean if ML fails (e.g. missing assets)
        return const PrefilterResult.clean();
      }
    }
    return const PrefilterResult.clean();
  }

  PrefilterResult _checkRegex(String text) {
    if (_cardStrict.hasMatch(text) && !_cardExclude.hasMatch(text)) {
      return const PrefilterResult.sensitive(reason: 'Credit card number detected');
    }
    if (_googleKey.hasMatch(text) || _openAiKey.hasMatch(text) ||
        _anthropic.hasMatch(text)  || _awsKey.hasMatch(text)   ||
        _githubPat.hasMatch(text)  || _stripeKey.hasMatch(text)) {
      return const PrefilterResult.sensitive(reason: 'API key or secret detected');
    }
    if (_pemKey.hasMatch(text)) {
      return const PrefilterResult.sensitive(reason: 'Private key detected');
    }
    return const PrefilterResult.clean();
  }
}
