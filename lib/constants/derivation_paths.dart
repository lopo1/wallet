class DerivationPaths {
  static const String solana = "m/44'/501'/0'/0'";

  static String solanaWithIndex(int index) {
    return "m/44'/501'/$index'/0'";
  }

  static String ethereumWithIndex(int index) {
    return "m/44'/60'/0'/0/$index";
  }

  static String bitcoinWithIndex(int index) {
    return "m/84'/0'/0'/0/$index"; // P2WPKH (bech32) derivation path
  }

  // TRON uses SLIP-0044 coin type 195
  static String tronWithIndex(int index) {
    return "m/44'/195'/0'/0/$index";
  }
}