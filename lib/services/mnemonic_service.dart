import 'package:bip39/bip39.dart' as bip39;

class MnemonicService {
  /// Generate a new mnemonic phrase
  /// [wordCount] can be 12 or 24 (default: 12)
  static String generateMnemonic({int wordCount = 12}) {
    if (wordCount != 12 && wordCount != 24) {
      throw ArgumentError('Word count must be 12 or 24');
    }
    
    // 12 words = 128 bits entropy, 24 words = 256 bits entropy
    final strength = wordCount == 12 ? 128 : 256;
    return bip39.generateMnemonic(strength: strength);
  }
  
  /// Validate a mnemonic phrase
  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic.trim());
  }
  
  /// Convert mnemonic to seed
  static List<int> mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    if (!validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic phrase');
    }
    return bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  }
  
  /// Get word count from mnemonic
  static int getWordCount(String mnemonic) {
    final words = mnemonic.trim().split(' ');
    return words.length;
  }
  
  /// Check if mnemonic has valid word count
  static bool hasValidWordCount(String mnemonic) {
    final wordCount = getWordCount(mnemonic);
    return wordCount == 12 || wordCount == 24;
  }
  
  /// Get entropy from mnemonic
  static String mnemonicToEntropy(String mnemonic) {
    if (!validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic phrase');
    }
    return bip39.mnemonicToEntropy(mnemonic);
  }
  
  /// Convert entropy to mnemonic
  static String entropyToMnemonic(String entropy) {
    return bip39.entropyToMnemonic(entropy);
  }
  
  /// Generate multiple mnemonics for testing
  static List<String> generateMultipleMnemonics(int count, {int wordCount = 12}) {
    final mnemonics = <String>[];
    for (int i = 0; i < count; i++) {
      mnemonics.add(generateMnemonic(wordCount: wordCount));
    }
    return mnemonics;
  }
  
  /// Split mnemonic into words
  static List<String> splitMnemonic(String mnemonic) {
    return mnemonic.trim().split(' ').where((word) => word.isNotEmpty).toList();
  }
  
  /// Join words into mnemonic
  static String joinWords(List<String> words) {
    return words.join(' ');
  }
  
  /// Normalize mnemonic (trim and lowercase)
  static String normalizeMnemonic(String mnemonic) {
    return mnemonic.trim().toLowerCase();
  }
  
  /// Check if two mnemonics are the same
  static bool compareMnemonics(String mnemonic1, String mnemonic2) {
    return normalizeMnemonic(mnemonic1) == normalizeMnemonic(mnemonic2);
  }
  
  /// Get mnemonic strength (entropy bits)
  static int getMnemonicStrength(String mnemonic) {
    final wordCount = getWordCount(mnemonic);
    switch (wordCount) {
      case 12:
        return 128;
      case 24:
        return 256;
      default:
        throw ArgumentError('Invalid word count: $wordCount');
    }
  }
  
  /// Generate checksum for mnemonic validation
  static bool verifyChecksum(String mnemonic) {
    try {
      final entropy = mnemonicToEntropy(mnemonic);
      final regenerated = entropyToMnemonic(entropy);
      return compareMnemonics(mnemonic, regenerated);
    } catch (e) {
      return false;
    }
  }
}