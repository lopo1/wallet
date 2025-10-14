import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import '../services/walletconnect_service.dart';

class QRScannerScreen extends StatefulWidget {
  final bool isForAddress; // 是否用于地址扫描
  
  const QRScannerScreen({super.key, this.isForAddress = false});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  bool? _flashStatus = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isForAddress ? '扫描地址二维码' : '扫描 WalletConnect QR码'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashStatus == true
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: () async {
              try {
                await controller?.toggleFlash();
                final flashStatus = await controller?.getFlashStatus();
                setState(() {
                  _flashStatus = flashStatus;
                });
              } catch (e) {
                // 忽略闪光灯错误，不影响扫描功能
                print('Flash error: $e');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Theme.of(context).primaryColor,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            '正在连接...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(
              minHeight: 120,
              maxHeight: 180,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isForAddress 
                        ? '将相机对准钱包地址二维码'
                        : '将相机对准 WalletConnect QR码',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isForAddress 
                        ? '扫描后将自动填入收款地址'
                        : '扫描后将自动连接到 DApp',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.photo_library,
                        label: '相册',
                        onPressed: _pickFromGallery,
                      ),
                      if (widget.isForAddress)
                        _buildActionButton(
                          icon: Icons.edit,
                          label: '手动输入',
                          onPressed: _showManualInputDialog,
                        ),
                      _buildActionButton(
                        icon: Icons.flip_camera_ios,
                        label: '翻转',
                        onPressed: _flipCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(28),
          ),
          child: IconButton(
            icon: Icon(icon, color: Theme.of(context).primaryColor),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _handleQRCode(scanData.code!);
      }
    });
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 暂停相机
      await controller?.pauseCamera();

      // 如果是地址扫描模式，直接返回扫描结果
      if (widget.isForAddress) {
        // 震动反馈
        HapticFeedback.mediumImpact();
        
        // 返回扫描到的地址
        if (mounted) {
          Navigator.of(context).pop(qrCode);
        }
        return;
      }

      // 检查是否是WalletConnect URI
      if (!qrCode.startsWith('wc:')) {
        _showError('无效的 WalletConnect QR码');
        return;
      }

      // 连接到WalletConnect
      final walletConnectService =
          Provider.of<WalletConnectService>(context, listen: false);

      if (!walletConnectService.isInitialized) {
        await walletConnectService.initialize();
      }

      await walletConnectService.connectWithUri(qrCode);

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WalletConnect 连接请求已发送'),
            backgroundColor: Colors.green,
          ),
        );

        // 返回上一页
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('连接失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        await controller?.resumeCamera();
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    // 这里可以实现从相册选择QR码图片的功能
    // 需要添加image_picker依赖和QR码识别库
    _showError('从相册选择功能暂未实现');
  }

  Future<void> _flipCamera() async {
    await controller?.flipCamera();
    setState(() {});
  }

  void _showManualInputDialog() {
    final TextEditingController textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '手动输入地址',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '请输入钱包地址',
            hintStyle: TextStyle(color: Colors.white38),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6C5CE7)),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final address = textController.text.trim();
              if (address.isNotEmpty) {
                Navigator.pop(context); // 关闭对话框
                Navigator.pop(context, address); // 返回地址
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '确认',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
