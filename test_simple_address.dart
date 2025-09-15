import 'package:flutter_wallet/services/address_service.dart';
import 'package:flutter_wallet/services/address_service.dart';
import 'package:flutter_wallet/services/mnemonic_service.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:solana/solana.dart';
import 'package:flutter_wallet/constants/derivation_paths.dart';

void main() async {
  print('测试助记词地址生成一致性...\n');

  // 生成一个测试助记词
  // final testMnemonic = MnemonicService.generateMnemonic();
  final testMnemonic =
      "what cloth hold life mammal patch aerobic fluid dry lobster ozone ring";
  print('测试助记词: $testMnemonic\n');

  // 方法1: 使用AddressService生成地址（索引0）
  final addressServiceAddress = await AddressService.generateAddress(
    mnemonic: testMnemonic,
    network: 'solana',
    index: 0,
  );
  print('AddressService生成的地址 (index=0): $addressServiceAddress');

  // 方法2: 使用修复后的SolanaWalletService相同的逻辑
  final seed = MnemonicService.mnemonicToSeed(testMnemonic);
  const path = DerivationPaths.solana;
  final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
  final keypair =
      await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: derivedKey.key);
  final walletServiceAddress = keypair.publicKey.toBase58();
  print('SolanaWalletService逻辑生成的地址: $walletServiceAddress');

  // 检查是否一致
  if (walletServiceAddress == addressServiceAddress) {
    print('\n✅ 地址一致！修复成功！');
  } else {
    print('\n❌ 地址不一致，需要进一步检查');
    print('差异:');
    print('  WalletService逻辑: $walletServiceAddress');
    print('  AddressService: $addressServiceAddress');
  }

  // 测试已知助记词
  const knownMnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  if (MnemonicService.validateMnemonic(knownMnemonic)) {
    print('\n测试已知助记词...');

    final knownAddr1 = await AddressService.generateAddress(
      mnemonic: knownMnemonic,
      network: 'solana',
      index: 0,
    );

    final knownSeed = MnemonicService.mnemonicToSeed(knownMnemonic);
    final knownDerivedKey = await ED25519_HD_KEY.derivePath(path, knownSeed);
    final knownKeypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: knownDerivedKey.key);
    final knownAddr2 = knownKeypair.publicKey.toBase58();

    print('已知助记词地址一致性: ${knownAddr1 == knownAddr2 ? '✅' : '❌'}');
    print('AddressService: $knownAddr1');
    print('WalletService逻辑: $knownAddr2');
  }
}
