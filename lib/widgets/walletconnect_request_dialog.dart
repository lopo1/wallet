import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

/// WalletConnect请求确认对话框
class WalletConnectRequestDialog extends StatelessWidget {
  final SessionRequestEvent event;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const WalletConnectRequestDialog({
    super.key,
    required this.event,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final method = event.params.request.method;
    final params = event.params.request.params;
    
    return AlertDialog(
      title: Text(_getDialogTitle(method)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDAppInfo(),
            const SizedBox(height: 16),
            _buildRequestDetails(method, params),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: const Text('拒绝'),
        ),
        ElevatedButton(
          onPressed: onApprove,
          child: const Text('确认'),
        ),
      ],
    );
  }

  String _getDialogTitle(String method) {
    switch (method) {
      case 'eth_sendTransaction':
      case 'eth_signTransaction':
        return '确认交易';
      case 'personal_sign':
      case 'eth_sign':
        return '确认签名';
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
        return '确认类型化数据签名';
      case 'solana_signTransaction':
        return '确认Solana交易';
      case 'solana_signMessage':
        return '确认Solana消息签名';
      default:
        return '确认请求';
    }
  }

  Widget _buildDAppInfo() {
    final metadata = event.params.request.params;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.web,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DApp请求',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  event.topic,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails(String method, dynamic params) {
    switch (method) {
      case 'eth_sendTransaction':
      case 'eth_signTransaction':
        return _buildTransactionDetails(params);
      case 'personal_sign':
      case 'eth_sign':
        return _buildSignDetails(params);
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
        return _buildTypedDataDetails(params);
      case 'solana_signTransaction':
        return _buildSolanaTransactionDetails(params);
      case 'solana_signMessage':
        return _buildSolanaMessageDetails(params);
      default:
        return _buildGenericDetails(params);
    }
  }

  Widget _buildTransactionDetails(dynamic params) {
    if (params is! List || params.isEmpty) {
      return const Text('无效的交易参数');
    }

    final tx = params[0] as Map<String, dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '交易详情:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (tx['to'] != null) ...[
        
          _buildDetailRow('接收地址', tx['to'].toString()),
        ],
        if (tx['value'] != null) ...[
        
          _buildDetailRow('金额', _formatValue(tx['value'].toString())),
        ],
        if (tx['gas'] != null) ...[
        
          _buildDetailRow('Gas限制', tx['gas'].toString()),
        ],
        if (tx['gasPrice'] != null) ...[
        
          _buildDetailRow('Gas价格', tx['gasPrice'].toString()),
        ],
        if (tx['data'] != null && tx['data'].toString().isNotEmpty) ...[
        
          _buildDetailRow('数据', tx['data'].toString(), isExpandable: true),
        ],
      ],
    );
  }

  Widget _buildSignDetails(dynamic params) {
    if (params is! List || params.isEmpty) {
      return const Text('无效的签名参数');
    }

    final message = params[0].toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '签名消息:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatMessage(message),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildTypedDataDetails(dynamic params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '类型化数据签名:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            params.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildSolanaTransactionDetails(dynamic params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Solana交易:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            params.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildSolanaMessageDetails(dynamic params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Solana消息签名:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            params.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericDetails(dynamic params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '请求参数:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            params.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isExpandable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isExpandable && value.length > 50 
                  ? '${value.substring(0, 50)}...'
                  : value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(String value) {
    try {
      // 尝试将Wei转换为ETH
      if (value.startsWith('0x')) {
        final wei = BigInt.parse(value.substring(2), radix: 16);
        final eth = wei / BigInt.from(1000000000000000000);
        return '$eth ETH';
      }
      return value;
    } catch (e) {
      return value;
    }
  }

  String _formatMessage(String message) {
    try {
      // 如果是十六进制编码的消息，尝试解码
      if (message.startsWith('0x')) {
        final bytes = message.substring(2);
        final decoded = String.fromCharCodes(
          List.generate(bytes.length ~/ 2, (i) => 
            int.parse(bytes.substring(i * 2, i * 2 + 2), radix: 16)
          )
        );
        return decoded;
      }
      return message;
    } catch (e) {
      return message;
    }
  }
}