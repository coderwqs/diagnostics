import 'package:diagnosis/model/features.dart';
import 'package:diagnosis/model/history.dart';
import 'package:diagnosis/service/features.dart';
import 'package:diagnosis/service/history.dart';
import 'package:diagnosis/utils/file_parser/parser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DataImportScreen extends StatefulWidget {
  const DataImportScreen({super.key});

  @override
  createState() => _DataImportScreenState();
}

class _DataImportScreenState extends State<DataImportScreen> {
  final HistoryService _historyService = HistoryService();
  final FeaturesService _featuresService = FeaturesService();

  List<PlatformFile> _selectedFiles = [];
  bool _isImporting = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('数据导入', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 文件选择框 - 顶部浮动 (宽度拉满)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Container(
              width: double.infinity, // 宽度拉满
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickFiles,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '点击或拖拽文件到此处',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '支持 CSV、JSON、Excel 格式文件',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (_selectedFiles.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '已选择 ${_selectedFiles.length} 个文件',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 文件列表 - 中间可滚动区域
          Expanded(
            child: _selectedFiles.isEmpty
                ? _buildEmptyState() // 优化空状态显示
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _selectedFiles.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getFileIconColor(
                                  file.extension,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getFileIcon(file.extension),
                                color: _getFileIconColor(file.extension),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${(file.size / 1024).toStringAsFixed(1)} KB',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        file.extension?.toUpperCase() ?? '未知',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 20),
                              onPressed: () => _removeFile(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 底部按钮区域
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_isImporting) ...[
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '正在导入 ${_selectedFiles.length} 个文件 (${(_progress * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _selectedFiles.isEmpty || _isImporting
                        ? null
                        : _startImport,
                    child: Text(
                      _isImporting
                          ? '处理中...'
                          : '开始导入 (${_selectedFiles.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 优化空状态显示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '暂无文件',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请点击上方区域或拖拽文件到此处',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.code;
      case 'xlsx':
      case 'xls':
        return Icons.insert_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'csv':
        return Colors.orange;
      case 'json':
        return Colors.purple;
      case 'xlsx':
      case 'xls':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json', 'xlsx', 'xls'],
        dialogTitle: '选择数据文件',
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件选择出错: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _startImport() async {
    setState(() {
      _isImporting = true;
      _progress = 0.0;
    });

    final allErrors = <DataError>[];
    int totalSuccess = 0;

    try {
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        await Future.delayed(Duration(milliseconds: 200));

        try {
          final result = await HistoryImportManager.importFile(
            file: file,
            config: ImportConfig(
              skipFirstRow: true,
              maxRows: 5000,
              validateDeviceId: true,
              validateDataTime: true,
            ),
            onProgress: (progress) async {
              final totalProgress = (i + progress) / _selectedFiles.length;
              setState(() => _progress = totalProgress);
            },
          );

          // 写入数据库 result.record
          persistImportData(result.records);

          totalSuccess += result.successCount;
          allErrors.addAll(result.errors);
        } catch (e) {
          allErrors.add(
            DataError(message: '文件 ${file.name} 导入失败: ${e.toString()}'),
          );
        }
      }

      _showImportResult(
        successCount: totalSuccess,
        errorCount: allErrors.length,
        errors: allErrors,
        fileCount: _selectedFiles.length,
      );
    } catch (e) {
      _showErrorDialog('导入过程中出错', e.toString());
    }

    setState(() {
      _isImporting = false;
    });
  }

  void persistImportData(List<History> records) {
    for(var h in records){
      _historyService.addHistory(h);
      
      Feature feature = Feature.calculateFeatures(waveform: h.data);
      feature.dataTime = h.dataTime;
      feature.deviceId = h.deviceId;
      _featuresService.addFeature(feature);
    }
  }

  void _showImportResult({
    required int successCount,
    required int errorCount,
    required List<DataError> errors,
    required int fileCount,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                errorCount == 0 ? Icons.check_circle : Icons.warning,
                color: errorCount == 0 ? Colors.green : Colors.orange,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                errorCount == 0 ? '导入成功' : '导入完成',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '处理了 $fileCount 个文件\n'
                '成功: $successCount 条\n'
                '错误: $errorCount 条',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              if (errors.isNotEmpty) ...[
                SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Card(
                    child: ListView.builder(
                      itemCount: errors.length,
                      itemBuilder: (context, index) {
                        final error = errors[index];
                        return ListTile(
                          title: Text(
                            error.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: error.rowNumber != null
                              ? Text('行号: ${error.rowNumber}')
                              : null,
                          dense: true,
                        );
                      },
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('确定'),
                    ),
                  ),
                  if (errors.isNotEmpty)
                    Text('导出错误', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}
