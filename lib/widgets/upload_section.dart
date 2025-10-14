import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UploadSection extends StatefulWidget {
  final Function(List<String>)? onFilesSelected;
  final VoidCallback? onUploadPressed;
  final bool isUploading;
  final double uploadProgress;
  final List<String> selectedFiles;

  const UploadSection({
    super.key,
    this.onFilesSelected,
    this.onUploadPressed,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.selectedFiles = const [],
  });

  @override
  State<UploadSection> createState() => _UploadSectionState();
}

class _UploadSectionState extends State<UploadSection> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = isDark ? const Color(0xFF1A1D29) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 上传区域
          GestureDetector(
            onTap: _selectFiles,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _isDragOver ? primaryColor.withOpacity(0.1) : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDragOver ? primaryColor : Colors.grey.shade300,
                  width: _isDragOver ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: _isDragOver ? primaryColor : secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '拖拽文件到此处或点击上传',
                    style: TextStyle(
                      color: _isDragOver ? primaryColor : textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '支持多种文件格式',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 文件列表
          if (widget.selectedFiles.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已选择文件',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.selectedFiles.map((file) => _buildFileItem(file, textColor, secondaryTextColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 上传按钮
          if (widget.selectedFiles.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.isUploading ? null : widget.onUploadPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: widget.isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '上传中 ${(widget.uploadProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : const Text(
                        '开始上传',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileItem(String fileName, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            color: secondaryTextColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: secondaryTextColor,
              size: 16,
            ),
            onPressed: () => _removeFile(fileName),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFiles() async {
    try {
      // 模拟文件选择
      final mockFiles = [
        'document.pdf',
        'image.jpg',
        'wallet_backup.json',
      ];
      
      if (widget.onFilesSelected != null) {
        widget.onFilesSelected!(mockFiles);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('选择文件失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile(String fileName) {
    final updatedFiles = List<String>.from(widget.selectedFiles);
    updatedFiles.remove(fileName);
    
    if (widget.onFilesSelected != null) {
      widget.onFilesSelected!(updatedFiles);
    }
  }
}