import 'package:meta/meta.dart';

@immutable
abstract class WalletEvent {}

class WalletInitialized extends WalletEvent {
  WalletInitialized({required this.address});
  final String address;
}

class WalletCreated extends WalletEvent {
  WalletCreated({required this.mnemonic, required this.address});
  final String mnemonic;
  final String address;
}

class TransactionCompleted extends WalletEvent {
  TransactionCompleted({
    required this.signature,
    required this.isSuccess,
    this.slot,
    this.error,
  });
  final String signature;
  final bool isSuccess;
  final int? slot;
  final String? error;
}