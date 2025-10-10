import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import '../services/walletconnect_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

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
        title: const Text('扫描 WalletConnect QR码'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              controller?.getFlashStatus() == true
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: () async {
              await controller?.toggleFlash();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
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
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '将相机对准 WalletConnect QR码',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '扫描后将自动连接到 DApp',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.photo_library,
                        label: '相册',
                        onPressed: _pickFromGallery,
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
