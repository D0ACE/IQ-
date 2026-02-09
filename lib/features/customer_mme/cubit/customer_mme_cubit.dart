import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_state.dart';
import 'package:iq_plus/features/customer_mme/models/mme_model_req.dart';
import 'dart:typed_data';
import 'package:iq_plus/features/customer_mme/repository/customer_mme_repository.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class CustomerMMECubit extends Cubit<CustomerMMEState> {
  final CustomerMMERepository repository;

  CustomerMMECubit(this.repository) : super(CustomerMMEInitial());

  Future<void> createMME({
    required String customerId,
    required String serial,
    required String device,
    required DateTime lastDate,
    required DateTime nextDate,
  }) async {
    emit(CustomerMMELoading());
    try {
      await repository.createMME(
        customerId: customerId,
        serialNumber: serial,
        deviceName: device,
        lastDate: lastDate,
        nextDate: nextDate,
      );
      emit(CustomerMMESuccess());
    } catch (e) {
      emit(CustomerMMEError(e.toString()));
    }
  }

  Future<void> loadMME(String customerId) async {
    emit(CustomerMMELoading());
    try {
      final list = await repository.fetchCustomerMME(customerId);
      emit(CustomerMMELoaded(list));
    } catch (e) {
      emit(CustomerMMEError(e.toString()));
    }
  }


  Future<void> deleteMME(String docId, String customerId) async {
    try {
      emit(CustomerMMELoading());

      await repository.deleteMME(docId);

      // reload list after delete
      final list = await repository.fetchCustomerMME(customerId);
      emit(CustomerMMELoaded(list));
    } catch (e) {
      emit(CustomerMMEError(e.toString()));
    }
  }

  Future<void> updateMME({
    required String docId,
    required String customerId,
    required String mmeId,
    required String serial,
    required String device,
    required DateTime lastDate,
    required DateTime nextDate,
  }) async {
    emit(CustomerMMELoading());
    try {
      await repository.updateMME(
        docId: docId,
        customerId: customerId,
        mmeId: mmeId,
        serial: serial,
        device: device,
        lastDate: lastDate,
        nextDate: nextDate,
      );
      emit(CustomerMMESuccess());
    } catch (e) {
      emit(CustomerMMEError(e.toString()));
    }
  }


// Flexible date parser
  DateTime? parseAnyDate(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    final cleanText = text.replaceAll('\n', '').trim();

    // Try common formats
    const formats = [
      'yyyy-MM-dd', // 2024-01-01
      'dd-MM-yyyy', // 01-01-2024
      'MM-dd-yyyy', // 01-31-2024
      'dd/MM/yyyy', // 01/01/2024
      'MM/dd/yyyy', // 01/31/2024
      'yyyy/MM/dd', // 2024/01/01
      'dd MMM yyyy', // 01 Jan 2024
      'MMM dd, yyyy', // Jan 01, 2024
    ];

    for (final f in formats) {
      try {
        return DateFormat(f).parseStrict(cleanText);
      } catch (_) {}
    }

    // Fallback: try DateTime.parse
    try {
      return DateTime.parse(cleanText);
    } catch (_) {}

    return null;
  }

// Read CSV uploaded by user (Flutter Web)
  Future<List<CustomerMMEModel>> readMMEFromCsvWeb() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null) return [];

    final Uint8List bytes = result.files.single.bytes!;
    final csvString = String.fromCharCodes(bytes);

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(csvString);

    if (rows.isEmpty) return [];

    // Map headers dynamically
    final header = rows[0].map((e) => e.toString().trim()).toList();
    final serialIndex = header.indexOf('serialNumber');
    final deviceIndex = header.indexOf('deviceName');
    final lastDateIndex = header.indexOf('lastCalibrationDate');
    final nextDateIndex = header.indexOf('nextCalibrationDate');

    if ([serialIndex, deviceIndex, lastDateIndex, nextDateIndex].contains(-1)) {
      throw Exception('CSV headers missing or invalid!');
    }

    final List<CustomerMMEModel> list = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      // Skip misaligned rows
      if (row.length < header.length) continue;

      final serial = row[serialIndex]?.toString().trim() ?? '';
      final device = row[deviceIndex]?.toString().trim() ?? '';
      final lastDateStr = row[lastDateIndex]?.toString();
      final nextDateStr = row[nextDateIndex]?.toString();

      if (serial.isEmpty || device.isEmpty) continue;

      final lastDate = parseAnyDate(lastDateStr);
      final nextDate = parseAnyDate(nextDateStr);

      if (lastDate == null || nextDate == null) continue;
      if (nextDate.isBefore(lastDate)) continue;

      list.add(CustomerMMEModel(
        id: '0',
        customerId: '',
        serialNumber: serial,
        deviceName: device,
        lastCalibrationDate: lastDate,
        nextCalibrationDate: nextDate,
      ));
    }

    return list;
  }


  Future<void> uploadExcelMME(
      String customerId,
      List<CustomerMMEModel> list,
      ) async {
    emit(CustomerMMELoading());
    await repository.createMMEBulk(customerId, list);
    await loadMME(customerId);
  }

  Future<void> downloadMMECsvTemplateWeb() async {
    //Demo data add CSV
/*    const csv = '''
serialNumber,deviceName,lastCalibrationDate,nextCalibrationDate
SN-001,Pressure Gauge,01-01-2024,01-01-2025
SN-002,CC Gauge,06-01-2024,03-06-2025
SN-003,GG AA,03-08-2024,09-08-2025
''';*/

    const csv = '''
serialNumber,deviceName,lastCalibrationDate,nextCalibrationDate
''';

    final blob = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = 'customer_mme_template.csv'
      ..click();

    html.Url.revokeObjectUrl(url);
  }



// Future<File> generateMMEExcelTemplate() async {
  //   final excel = Excel.createExcel();
  //   final sheet = excel['MME'];
  //
  //   /// Header row
  //   sheet.appendRow([
  //     TextCellValue('serialNumber'),
  //     TextCellValue('deviceName'),
  //     TextCellValue('lastCalibrationDate'),
  //     TextCellValue('nextCalibrationDate'),
  //   ]);
  //
  //   /// Sample data row
  //   sheet.appendRow([
  //     TextCellValue('SN-001'),
  //     TextCellValue('Pressure Gauge'),
  //     TextCellValue('01-01-2024'),
  //     TextCellValue('01-01-2025'),
  //   ]);
  //
  //   final directory = await getApplicationDocumentsDirectory();
  //   final file = File(
  //     '${directory.path}/customer_mme_template.xlsx',
  //   );
  //
  //   await file.writeAsBytes(excel.encode()!, flush: true);
  //   return file;
  // }

}
