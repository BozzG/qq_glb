import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'database_helper.dart';

/// 数据备份与恢复服务。
///
/// · 导出：将全部业务表序列化为 JSON 文件，经系统分享面板导出（保存到文件/隔空投送/云盘等）。
/// · 恢复：用户选取此前导出的 JSON 备份文件，校验后整库覆盖恢复（单事务，失败回滚）。
///
/// 说明：备份仅包含数据库中的结构化数据；日记/医疗记录中引用的图片、视频等媒体文件
/// 以路径形式存储，不随 JSON 一并打包，恢复到新设备后媒体可能丢失（v2.3 已知限制）。
class BackupService {
  BackupService({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  final DatabaseHelper _db;

  /// 备份文件格式版本，用于未来兼容性判断。
  static const int backupVersion = 1;

  /// 备份文件标识，恢复时校验来源。
  static const String appTag = 'qianqian_growth_logbook';

  /// 构建一份备份内容（纯数据，不落盘），便于测试与复用。
  Future<Map<String, dynamic>> buildBackupPayload() async {
    final tables = await _db.exportAllTables();
    final totalRows =
        tables.values.fold<int>(0, (sum, rows) => sum + rows.length);
    return {
      'app': appTag,
      'backupVersion': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'totalRows': totalRows,
      'tables': tables,
    };
  }

  /// 生成备份 JSON 文件到临时目录，返回文件对象。
  Future<File> writeBackupFile() async {
    final payload = await buildBackupPayload();
    final dir = await getTemporaryDirectory();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/qianqian_backup_$ts.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

  /// 导出并拉起系统分享面板。
  Future<void> exportAndShare() async {
    final file = await writeBackupFile();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: '芊芊成长日志数据备份',
      text: '芊芊成长日志数据备份文件，请妥善保存，可用于在新设备恢复数据。',
    );
  }

  /// 解析并校验备份内容，返回标准化的「表名→行列表」结构。
  /// 校验失败抛出 [FormatException]。
  Map<String, List<Map<String, dynamic>>> parseBackup(String content) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      throw const FormatException('备份文件不是有效的 JSON');
    }
    if (decoded is! Map || decoded['tables'] is! Map) {
      throw const FormatException('备份文件格式不正确，缺少 tables 字段');
    }
    if (decoded['app'] != null && decoded['app'] != appTag) {
      throw const FormatException('该备份文件不属于本应用');
    }
    final rawTables = decoded['tables'] as Map;
    final result = <String, List<Map<String, dynamic>>>{};
    for (final table in DatabaseHelper.allTables) {
      final raw = rawTables[table];
      if (raw == null) {
        result[table] = const [];
        continue;
      }
      if (raw is! List) {
        throw FormatException('备份文件中「$table」数据格式不正确');
      }
      result[table] = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }
    return result;
  }

  /// 让用户选取备份文件并恢复，返回恢复结果。
  Future<BackupImportResult> importFromPickedFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return BackupImportResult.cancelled();
    }
    final pf = picked.files.single;

    String content;
    if (pf.bytes != null) {
      content = utf8.decode(pf.bytes!);
    } else if (pf.path != null) {
      content = await File(pf.path!).readAsString();
    } else {
      throw const FormatException('无法读取所选文件');
    }

    final tables = parseBackup(content);
    final counts = await _db.importAll(tables);
    final total = counts.values.fold<int>(0, (s, v) => s + v);
    return BackupImportResult.success(total: total, perTable: counts);
  }
}

/// 恢复结果。
class BackupImportResult {
  /// 用户取消选择文件。
  final bool cancelled;

  /// 恢复成功写入的总行数。
  final int total;

  /// 每张表恢复的行数。
  final Map<String, int> perTable;

  const BackupImportResult._({
    required this.cancelled,
    required this.total,
    required this.perTable,
  });

  factory BackupImportResult.cancelled() =>
      const BackupImportResult._(cancelled: true, total: 0, perTable: {});

  factory BackupImportResult.success({
    required int total,
    required Map<String, int> perTable,
  }) =>
      BackupImportResult._(cancelled: false, total: total, perTable: perTable);
}
