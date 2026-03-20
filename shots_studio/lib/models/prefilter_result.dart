class PiiEntityTypes {
  static const creditCard    = 'credit card number';
  static const apiKey        = 'api key';
  static const password      = 'password';
  static const otp           = 'one-time password';
  static const bankAccount   = 'bank account number';
  static const routingNumber = 'routing number';
  static const iban          = 'IBAN';
  static const upi           = 'UPI ID';
  static const aadhaar       = 'aadhaar number';
  static const panCard       = 'PAN card number';
  static const ssn           = 'social security number';
  static const passport      = 'passport number';

  // Passed verbatim to GLiNER — zero-shot, add new strings to detect new types
  static const all = [
    creditCard, apiKey, password, otp,
    bankAccount, routingNumber, iban, upi,
    aadhaar, panCard, ssn, passport,
  ];
}

class PiiEntity {
  final String type;
  final String text;    // matched span (approximate)
  final double score;   // model confidence 0.0–1.0
  const PiiEntity({required this.type, required this.text, required this.score});
}

class PrefilterResult {
  final bool isSensitive;
  final String? reason;           // shown to user in PrefilterStatusSection
  final List<PiiEntity> entities;

  const PrefilterResult.clean()
      : isSensitive = false, reason = null, entities = const [];

  const PrefilterResult.sensitive({required String this.reason, this.entities = const []})
      : isSensitive = true;
}
