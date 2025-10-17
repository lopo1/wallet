import 'package:flutter/material.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'swap': 'Swap',
      'from': 'From',
      'to': 'To',
      'select_token': 'Select Token',
      'enter_amount': 'Enter Amount',
      'balance': 'Balance',
      'max': 'MAX',
      'exchange_rate': 'Exchange Rate',
      'price_impact': 'Price Impact',
      'minimum_received': 'Minimum Received',
      'slippage_tolerance': 'Slippage Tolerance',
      'network_fee': 'Network Fee',
      'route': 'Route',
      'quote_expiry': 'Quote Expiry',
      'transaction_details': 'Transaction Details',
      'security_tips': 'Security Tips',
      'address_verification': 'Address Verification',
      'slippage_settings': 'Slippage Settings',
      'transaction_time': 'Transaction Time',
      'execute_swap': 'Execute Swap',
      'insufficient_balance': 'Insufficient Balance',
      'same_token_error': 'Cannot swap same token',
      'enter_swap_amount': 'Enter swap amount',
      'select_tokens': 'Select tokens',
      'preparing_transaction': 'Preparing transaction...',
      'transaction_submitted': 'Transaction submitted, waiting for confirmation...',
      'transaction_confirmed': 'Transaction confirmed successfully!',
      'transaction_failed': 'Transaction failed, please try again',
      'transaction_cancelled': 'Transaction cancelled',
      'address_format_invalid': 'Invalid address format',
      'address_format_valid': 'Valid address format',
      'paste': 'Paste',
      'recipient_address': 'Recipient Address (Optional)',
      'settings': 'Settings',
      'minutes': 'minutes',
      'expired': 'Expired',
      'low_impact': 'Low Impact',
      'medium_impact': 'Medium Impact',
      'high_impact': 'High Impact',
      'very_high_impact': 'Very High Impact',
    },
    'zh': {
      'swap': '兑换',
      'from': '从',
      'to': '到',
      'select_token': '选择代币',
      'enter_amount': '输入数量',
      'balance': '余额',
      'max': '最大',
      'exchange_rate': '汇率',
      'price_impact': '价格影响',
      'minimum_received': '最小接收',
      'slippage_tolerance': '滑点容忍度',
      'network_fee': '网络费用',
      'route': '路由',
      'quote_expiry': '报价有效期',
      'transaction_details': '交易详情',
      'security_tips': '安全提示',
      'address_verification': '地址验证',
      'slippage_settings': '滑点设置',
      'transaction_time': '交易时间',
      'execute_swap': '执行兑换',
      'insufficient_balance': '余额不足',
      'same_token_error': '不能兑换相同的代币',
      'enter_swap_amount': '输入兑换数量',
      'select_tokens': '选择代币',
      'preparing_transaction': '正在准备交易...',
      'transaction_submitted': '交易已提交，等待确认...',
      'transaction_confirmed': '交易成功确认！',
      'transaction_failed': '交易失败，请重试',
      'transaction_cancelled': '交易已取消',
      'address_format_invalid': '地址格式无效',
      'address_format_valid': '地址格式正确',
      'paste': '粘贴',
      'recipient_address': '接收地址 (可选)',
      'settings': '设置',
      'minutes': '分钟',
      'expired': '已过期',
      'low_impact': '低影响',
      'medium_impact': '中等影响',
      'high_impact': '高影响',
      'very_high_impact': '极高影响',
    },
  };

  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get swap => _localizedValues[locale.languageCode]!['swap']!;
  String get from => _localizedValues[locale.languageCode]!['from']!;
  String get to => _localizedValues[locale.languageCode]!['to']!;
  String get selectToken => _localizedValues[locale.languageCode]!['select_token']!;
  String get enterAmount => _localizedValues[locale.languageCode]!['enter_amount']!;
  String get balance => _localizedValues[locale.languageCode]!['balance']!;
  String get max => _localizedValues[locale.languageCode]!['max']!;
  String get exchangeRate => _localizedValues[locale.languageCode]!['exchange_rate']!;
  String get priceImpact => _localizedValues[locale.languageCode]!['price_impact']!;
  String get minimumReceived => _localizedValues[locale.languageCode]!['minimum_received']!;
  String get slippageTolerance => _localizedValues[locale.languageCode]!['slippage_tolerance']!;
  String get networkFee => _localizedValues[locale.languageCode]!['network_fee']!;
  String get route => _localizedValues[locale.languageCode]!['route']!;
  String get quoteExpiry => _localizedValues[locale.languageCode]!['quote_expiry']!;
  String get transactionDetails => _localizedValues[locale.languageCode]!['transaction_details']!;
  String get securityTips => _localizedValues[locale.languageCode]!['security_tips']!;
  String get addressVerification => _localizedValues[locale.languageCode]!['address_verification']!;
  String get slippageSettings => _localizedValues[locale.languageCode]!['slippage_settings']!;
  String get transactionTime => _localizedValues[locale.languageCode]!['transaction_time']!;
  String get executeSwap => _localizedValues[locale.languageCode]!['execute_swap']!;
  String get insufficientBalance => _localizedValues[locale.languageCode]!['insufficient_balance']!;
  String get sameTokenError => _localizedValues[locale.languageCode]!['same_token_error']!;
  String get enterSwapAmount => _localizedValues[locale.languageCode]!['enter_swap_amount']!;
  String get selectTokens => _localizedValues[locale.languageCode]!['select_tokens']!;
  String get preparingTransaction => _localizedValues[locale.languageCode]!['preparing_transaction']!;
  String get transactionSubmitted => _localizedValues[locale.languageCode]!['transaction_submitted']!;
  String get transactionConfirmed => _localizedValues[locale.languageCode]!['transaction_confirmed']!;
  String get transactionFailed => _localizedValues[locale.languageCode]!['transaction_failed']!;
  String get transactionCancelled => _localizedValues[locale.languageCode]!['transaction_cancelled']!;
  String get addressFormatInvalid => _localizedValues[locale.languageCode]!['address_format_invalid']!;
  String get addressFormatValid => _localizedValues[locale.languageCode]!['address_format_valid']!;
  String get paste => _localizedValues[locale.languageCode]!['paste']!;
  String get recipientAddress => _localizedValues[locale.languageCode]!['recipient_address']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get minutes => _localizedValues[locale.languageCode]!['minutes']!;
  String get expired => _localizedValues[locale.languageCode]!['expired']!;
  String get lowImpact => _localizedValues[locale.languageCode]!['low_impact']!;
  String get mediumImpact => _localizedValues[locale.languageCode]!['medium_impact']!;
  String get highImpact => _localizedValues[locale.languageCode]!['high_impact']!;
  String get veryHighImpact => _localizedValues[locale.languageCode]!['very_high_impact']!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}