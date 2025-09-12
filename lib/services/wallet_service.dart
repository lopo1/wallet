import 'package:flutter_wallet/services/transaction_monitor_service.dart';

import 'package:flutter_wallet/services/transaction_monitor_service.dart';

abstract class WalletService {
  Future<String> createWallet();
  Future<String> getAddress(String mnemonic);
  Future<double> getBalance(String address);
  Future<String> sendTransaction(String mnemonic, String toAddress, double amount);
  Future<double> estimateFee(String mnemonic, String toAddress, double amount);
  Future<TransactionStatus> getTransactionStatus(String signature);
}