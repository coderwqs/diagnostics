import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:diagnosis/model/history.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

class ImportConfig {
  final bool skipFirstRow;
  final int maxRows;
  final bool validateDeviceId;
  final bool validateDataTime;

  const ImportConfig({
    this.skipFirstRow = true,
    this.maxRows = 10000,
    this.validateDeviceId = true,
    this.validateDataTime = true,
  });
}

class DataError {
  final int? rowNumber;
  final String message;
  final String? fieldName;
  final dynamic invalidValue;
  final String? sourceFile;

  DataError({
    this.rowNumber,
    required this.message,
    this.fieldName,
    this.invalidValue,
    this.sourceFile,
  });
}

class ImportedHistoryData {
  final List<History> records;
  final String sourceFileName;
  final DateTime importTime;
  final int successCount;
  final int errorCount;
  final List<DataError> errors;

  ImportedHistoryData({
    required this.records,
    required this.sourceFileName,
    required this.successCount,
    this.errorCount = 0,
    this.errors = const [],
  }) : importTime = DateTime.now();
}

abstract class HistoryFileParser {
  Future<ImportedHistoryData> parse({
    required PlatformFile file,
    required ImportConfig config,
    required ValueChanged<double> onProgress,
  });
}

class HistoryCsvParser implements HistoryFileParser {
  @override
  Future<ImportedHistoryData> parse({
    required PlatformFile file,
    required ImportConfig config,
    required ValueChanged<double> onProgress,
  }) async {
    final input = File(file.path!).openRead();
    final rows = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter(eol: "\n"))
        .toList();

    final records = <History>[];
    final errors = <DataError>[];
    int successCount = 0;

    final startIndex = config.skipFirstRow ? 1 : 0;
    final endIndex = rows.length > config.maxRows
        ? startIndex + config.maxRows
        : rows.length;

    for (int i = startIndex; i < endIndex; i++) {
      try {
        final row = rows[i];
        if (row.length >= 6) {
          final history = _parseHistoryRow(row, config);
          records.add(history);
          successCount++;
        } else {
          throw FormatException('行数据不完整，应有6列但实际只有${row.length}列');
        }
      } catch (e, stackTrace) {
        errors.add(DataError(
          rowNumber: i + 1,
          message: e.toString(),
          fieldName: _getErrorField(e),
        ));
      }

      onProgress((i - startIndex + 1) / (endIndex - startIndex));
    }

    return ImportedHistoryData(
      records: records,
      sourceFileName: file.name,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
    );
  }

  History _parseHistoryRow(List<dynamic> row, ImportConfig config) {
    // 设备ID验证
    final deviceId = row[0].toString();
    if (config.validateDeviceId && deviceId.isEmpty) {
      throw FormatException('设备ID不能为空');
    }

    // 数据时间验证
    final dataTime = _parseInt(row[1], 'dataTime');
    if (config.validateDataTime && dataTime <= 0) {
      throw FormatException('数据时间必须为正整数');
    }

    // 采样率
    final samplingRate = _parseDouble(row[2], 'samplingRate');

    // 转速
    final rotationSpeed = _parseInt(row[3], 'rotationSpeed');

    // 数据列
    List<double> data = [];
    if (row[4] != null && row[4].toString().isNotEmpty) {
      try {
        data = List<double>.from(jsonDecode(row[4].toString()));
      } catch (e) {
        throw FormatException('数据列格式错误: ${e.toString()}');
      }
    }

    // 创建时间
    final createdAt = _parseInt(row[5], 'createdAt');

    return History(
      deviceId: deviceId,
      dataTime: dataTime,
      samplingRate: samplingRate,
      rotationSpeed: rotationSpeed,
      data: data,
      createdAt: createdAt,
    );
  }

  int _parseInt(dynamic value, String fieldName) {
    try {
      return int.parse(value.toString());
    } catch (e) {
      throw FormatException('$fieldName 应为整数但获取到 "$value"');
    }
  }

  double _parseDouble(dynamic value, String fieldName) {
    try {
      return double.parse(value.toString());
    } catch (e) {
      throw FormatException('$fieldName 应为浮点数但获取到 "$value"');
    }
  }

  String? _getErrorField(dynamic error) {
    if (error is FormatException) {
      final message = error.message;
      if (message.contains('设备ID')) return 'deviceId';
      if (message.contains('dataTime')) return 'dataTime';
      if (message.contains('samplingRate')) return 'samplingRate';
      if (message.contains('rotationSpeed')) return 'rotationSpeed';
      if (message.contains('createdAt')) return 'createdAt';
      if (message.contains('数据列')) return 'data';
    }
    return null;
  }
}

class HistoryExcelParser implements HistoryFileParser {
  @override
  Future<ImportedHistoryData> parse({
    required PlatformFile file,
    required ImportConfig config,
    required ValueChanged<double> onProgress,
  }) async {
    final bytes = await File(file.path!).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final records = <History>[];
    final errors = <DataError>[];
    int successCount = 0;

    final startIndex = config.skipFirstRow ? 1 : 0;
    final endIndex = sheet.rows.length > config.maxRows
        ? startIndex + config.maxRows
        : sheet.rows.length;

    for (int i = startIndex; i < endIndex; i++) {
      try {
        final row = sheet.rows[i];
        if (row.length >= 6) {
          final history = _parseHistoryRow(row, config);
          records.add(history);
          successCount++;
        } else {
          throw FormatException('行数据不完整，应有6列但实际只有${row.length}列');
        }
      } catch (e) {
        errors.add(DataError(
          rowNumber: i + 1,
          message: e.toString(),
        ));
      }

      onProgress((i - startIndex + 1) / (endIndex - startIndex));
    }

    return ImportedHistoryData(
      records: records,
      sourceFileName: file.name,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
    );
  }

  History _parseHistoryRow(List<Data?> row, ImportConfig config) {
    final deviceId = row[0]?.value.toString() ?? '';
    if (config.validateDeviceId && deviceId.isEmpty) {
      throw FormatException('设备ID不能为空');
    }

    final dataTime = _parseInt(row[1]?.value, 'dataTime');
    if (config.validateDataTime && dataTime <= 0) {
      throw FormatException('数据时间必须为正整数');
    }

    final samplingRate = _parseDouble(row[2]?.value, 'samplingRate');
    final rotationSpeed = _parseInt(row[3]?.value, 'rotationSpeed');

    List<double> data = [];
    if (row[4] != null && row[4]?.value.toString().isNotEmpty == true) {
      try {
        data = List<double>.from(jsonDecode(row[4]!.value.toString()));
      } catch (e) {
        throw FormatException('数据列格式错误: ${e.toString()}');
      }
    }

    final createdAt = _parseInt(row[5]?.value, 'createdAt');

    return History(
      deviceId: deviceId,
      dataTime: dataTime,
      samplingRate: samplingRate,
      rotationSpeed: rotationSpeed,
      data: data,
      createdAt: createdAt,
    );
  }

  static int _parseInt(dynamic value, String fieldName) {
    try {
      return int.parse(value.toString());
    } catch (e) {
      throw FormatException('$fieldName 应为整数但获取到 "$value"');
    }
  }

  static double _parseDouble(dynamic value, String fieldName) {
    try {
      return double.parse(value.toString());
    } catch (e) {
      throw FormatException('$fieldName 应为浮点数但获取到 "$value"');
    }
  }
}

class HistoryImportManager {
  static Future<ImportedHistoryData> importFile({
    required PlatformFile file,
    required ImportConfig config,
    required ValueChanged<double> onProgress,
  }) async {
    final parser = _getParserForFile(file);
    return await parser.parse(
      file: file,
      config: config,
      onProgress: onProgress,
    );
  }

  static HistoryFileParser _getParserForFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase();

    switch (extension) {
      case 'csv':
        return HistoryCsvParser();
      case 'xlsx':
      case 'xls':
        return HistoryExcelParser();
    // 可以根据需要添加JSON解析器
      default:
        throw UnsupportedError('不支持的文件格式: $extension');
    }
  }
}