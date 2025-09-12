import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:solana/solana.dart';
import 'package:flutter_wallet/services/wallet_service.dart';
import 'package:flutter_wallet/services/transaction_monitor_service.dart';
import 'package:flutter_wallet/services/mnemonic_service.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';

import 'package:flutter_wallet/models/solana_transaction.dart';

class SolanaWalletService implements WalletService {
  late RpcClient _rpcClient;

  SolanaWalletService(String rpcUrl) {
    _rpcClient = RpcClient(rpcUrl);
  }

  @override
  Future<String> createWallet() async {
    return bip39.generateMnemonic();
  }

  @override
  Future<String> getAddress(String mnemonic) async {
    final keypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
    return keypair.publicKey.toBase58();
  }

  @override
  Future<double> getBalance(String address) async {
    final balance = await _rpcClient.getBalance(address);
    return balance.value / lamportsPerSol;
  }

  @override
  Future<String> sendTransaction(
      String mnemonic, String toAddress, double amount) async {
    final fromKeypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
    final lamports = (amount * lamportsPerSol).toInt();

    final instruction = SystemInstruction.transfer(
      fundingAccount: fromKeypair.publicKey,
      recipientAccount: Ed25519HDPublicKey.fromBase58(toAddress),
      lamports: lamports,
    );

    final recentBlockhash = await _rpcClient.getLatestBlockhash();
    final message = Message.only(instruction);

    final signedTx = await fromKeypair.signMessage(
      message: message,
      recentBlockhash: recentBlockhash.value.blockhash,
    );

    final signature = await _rpcClient.sendTransaction(signedTx.encode());

    return signature;
  }

  @override
  Future<double> estimateFee(
      String mnemonic, String toAddress, double amount) async {
    final fromKeypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
    final lamports = (amount * lamportsPerSol).toInt();

    final instruction = SystemInstruction.transfer(
      fundingAccount: fromKeypair.publicKey,
      recipientAccount: Ed25519HDPublicKey.fromBase58(toAddress),
      lamports: lamports,
    );

    final message = Message.only(instruction);
    final recentBlockhash = await _rpcClient.getLatestBlockhash();
    final compiledMessage = message.compile(
      recentBlockhash: recentBlockhash.value.blockhash,
      feePayer: fromKeypair.publicKey,
    );
    final feeInLamports = await _rpcClient.getFeeForMessage(
        base64.encode(compiledMessage.toByteArray().toList()));
    return (feeInLamports ?? 0) / lamportsPerSol;
  }

  @override
  Future<TransactionStatus> getTransactionStatus(String signature) async {
    final result = await _rpcClient.getSignatureStatuses([signature]);
    if (result.value.isEmpty || result.value.first == null) {
      return TransactionStatus.pending;
    }
    final status = result.value.first!;
    if (status.err != null) {
      return TransactionStatus.failed;
    }
    if (status.confirmationStatus == Commitment.finalized) {
      return TransactionStatus.completed;
    }
    return TransactionStatus.pending;
  }

  void dispose() {
    // No resources to dispose of yet.
  }

  Future<SolanaTransaction> sendSolTransfer({
    required String mnemonic,
    required String fromAddress,
    required String toAddress,
    required double amount,
    required SolanaTransactionPriority priority,
    String? memo,
  }) async {
    try {
      // 使用与AddressService相同的方法生成密钥对
      final seed = MnemonicService.mnemonicToSeed(mnemonic);
      final path = "m/44'/501'/0'"; // 使用索引0，与AddressService相同
      final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);

      // 从派生的私钥创建Ed25519HDKeyPair
      final fromKeypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
          privateKey: derivedKey.key);
      final lamports = (amount * lamportsPerSol).toInt();

      // 获取从助记词生成的地址
      final generatedAddress = fromKeypair.publicKey.toBase58();

      // 验证地址匹配
      if (generatedAddress != fromAddress) {
        throw Exception(
            '发送地址与助记词不匹配 - 生成地址: $generatedAddress, 传入地址: $fromAddress');
      }

      // 创建转账指令
      final instruction = SystemInstruction.transfer(
        fundingAccount: fromKeypair.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(toAddress),
        lamports: lamports,
      );

      // 获取最新区块哈希
      final recentBlockhash = await _rpcClient.getLatestBlockhash();

      // 创建消息
      final message = Message.only(instruction);

      // 签名交易
      final signedTx = await fromKeypair.signMessage(
        message: message,
        recentBlockhash: recentBlockhash.value.blockhash,
      );

      // 发送交易
      final signature = await _rpcClient.sendTransaction(signedTx.encode());

      // 估算手续费
      final feeInLamports = await estimateFee(mnemonic, toAddress, amount);
      final totalFeeInLamports = (feeInLamports * lamportsPerSol).toInt();

      // 创建交易对象
      final transaction = SolanaTransaction.transfer(
        id: signature,
        fromAddress: fromAddress,
        toAddress: toAddress,
        amount: lamports,
        fee: SolanaTransactionFee(
          baseFee: 5000,
          priorityFee: totalFeeInLamports - 5000,
          totalFee: totalFeeInLamports,
          priorityMultiplier: _getPriorityMultiplier(priority),
        ),
        recentBlockhash: recentBlockhash.value.blockhash,
        priority: priority,
        memo: memo,
      );

      return transaction.copyWith(
        signature: signature,
        status: SolanaTransactionStatus.processing,
        sentAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('发送SOL转账失败: $e');
    }
  }

  /// 获取优先级倍数
  double _getPriorityMultiplier(SolanaTransactionPriority priority) {
    switch (priority) {
      case SolanaTransactionPriority.low:
        return 1.0;
      case SolanaTransactionPriority.medium:
        return 1.5;
      case SolanaTransactionPriority.high:
        return 2.0;
      case SolanaTransactionPriority.veryHigh:
        return 3.0;
    }
  }

  /// 使用与AddressService相同的方法生成Solana地址
  Future<String> _generateSolanaAddressLikeAddressService(
      String mnemonic, int index) async {
    try {
      // 这里我们需要导入相关的包来模拟AddressService的逻辑
      // 由于我们已经有了Ed25519HDKeyPair，让我们尝试不同的方法

      // 方法1：尝试使用默认的fromMnemonic方法
      final keypair0 = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      final address0 = keypair0.publicKey.toBase58();

      return address0;
    } catch (e) {
      throw Exception('无法生成AddressService风格的地址: $e');
    }
  }

  Future<void> storeDataOnChain(
      String mnemonic, Map<String, dynamic> data) async {
    // Placeholder implementation
  }

  Future<void> waitForTransactionConfirmation(String signature) async {
    const maxAttempts = 30; // 最多等待30次
    const delayBetweenAttempts = Duration(seconds: 2); // 每次间隔2秒

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final result = await _rpcClient.getSignatureStatuses([signature]);

        if (result.value.isNotEmpty && result.value.first != null) {
          final status = result.value.first!;

          // 如果交易失败
          if (status.err != null) {
            throw Exception('交易失败: ${status.err}');
          }

          // 如果交易已确认
          if (status.confirmationStatus == Commitment.confirmed ||
              status.confirmationStatus == Commitment.finalized) {
            return; // 交易确认成功
          }
        }

        // 等待下一次检查
        await Future.delayed(delayBetweenAttempts);
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          throw Exception('等待交易确认超时: $e');
        }
        await Future.delayed(delayBetweenAttempts);
      }
    }

    throw Exception('等待交易确认超时');
  }

  List<SolanaTransaction> getPendingTransactions() {
    // Placeholder implementation
    return [];
  }

  void cleanupCompletedTransactions() {
    // Placeholder implementation
  }
}
