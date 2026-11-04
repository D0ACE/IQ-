import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/rating.dart';
import '../models/supplier.dart';
import 'rating_calculator.dart';
import 'web_downloader.dart';

class ExportService {
  /// Converts a matrix of cells into an RFC 4180 compliant CSV string.
  static String convertToCsv(List<List<dynamic>> rows) {
    return rows
        .map((row) {
          return row
              .map((cell) {
                final str = cell?.toString() ?? '';
                if (str.contains(',') ||
                    str.contains('"') ||
                    str.contains('\n') ||
                    str.contains('\r')) {
                  return '"${str.replaceAll('"', '""')}"';
                }
                return str;
              })
              .join(',');
        })
        .join('\r\n');
  }

  /// Export Approved Suppliers List to CSV
  static void exportApprovedSuppliersToCsv(List<Supplier> suppliers) {
    final rows = <List<dynamic>>[];
    // Header
    rows.add([
      'APPROVED SUPPLIER\'S LIST (F-7.4-01/R01)',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);
    rows.add([
      'Sl No',
      'ID No',
      'Supplier Name',
      'Address',
      'Contact Person',
      'Phone / Fax',
      'Items Supplied / Service',
      'Method of Purchase',
      'Date of Inclusion',
      'Status',
    ]);

    for (int i = 0; i < suppliers.length; i++) {
      final s = suppliers[i];
      final contactStr = s.contacts.isNotEmpty
          ? '${s.contacts.first.name} (${s.contacts.first.designation})'
          : '-';
      final phoneFax = [
        s.phone,
        if (s.fax != null && s.fax!.isNotEmpty) 'Fax: ${s.fax}',
      ].join(', ');

      rows.add([
        i + 1,
        s.id,
        s.name,
        s.address,
        contactStr,
        phoneFax,
        s.productRange,
        s.purchaseMethod,
        s.dateOfInclusion,
        s.status,
      ]);
    }

    final csvData = convertToCsv(rows);
    FileDownloader.downloadTextFile(
      content: csvData,
      fileName: 'Approved_Suppliers_F-7.4-01.csv',
    );
  }

  /// Export Approved Suppliers List to PDF replicating F-7.4-01/R01
  static Future<void> exportApprovedSuppliersToPdf(
    List<Supplier> suppliers,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MANUFACTURING OPERATIONS - PURCHASE DEPARTMENT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'APPROVED SUPPLIER\'S LIST',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.blueGrey700,
                        width: 1,
                      ),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Format No: F-7.4-01/R01',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Row(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Prepared By: Purchase In-Charge',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Text(
                            '(Signature & Date)',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(width: 60),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Approved By: Director',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Text(
                            '(Signature & Date)',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8.5,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 4,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(28), // Sl No
                1: const pw.FixedColumnWidth(48), // ID
                2: const pw.FlexColumnWidth(3), // Supplier Name & Address
                3: const pw.FlexColumnWidth(1.8), // Contact Person
                4: const pw.FlexColumnWidth(1.8), // Phone/Fax
                5: const pw.FlexColumnWidth(3), // Items Supplied
                6: const pw.FlexColumnWidth(1.3), // Method
                7: const pw.FixedColumnWidth(55), // Date
                8: const pw.FixedColumnWidth(52), // Status
              },
              headers: [
                'Sl No',
                'ID No',
                'Supplier Name & Address',
                'Contact Person',
                'Phone / Fax',
                'Items Supplied / Service',
                'Method of Purchase',
                'Date of Inclusion',
                'Status',
              ],
              data: suppliers.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final s = entry.value;
                final contact = s.contacts.isNotEmpty
                    ? '${s.contacts.first.name}\n${s.contacts.first.designation}'
                    : '-';
                final phoneFax = [
                  s.phone,
                  if (s.fax != null && s.fax!.isNotEmpty) 'Fax: ${s.fax}',
                ].join('\n');

                return [
                  i.toString(),
                  s.id,
                  '${s.name}\n${s.address}',
                  contact,
                  phoneFax,
                  s.productRange,
                  s.purchaseMethod,
                  s.dateOfInclusion,
                  s.status,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Approved_Suppliers_F-7.4-01.pdf',
    );
  }

  /// Export Ratings to CSV
  static void exportRatingsToCsv({
    required String period,
    required List<Supplier> suppliers,
    required Map<String, Rating> ratingsMap,
    required double? averageTotal,
  }) {
    final rows = <List<dynamic>>[];
    rows.add(['SUPPLIER RATING FORM (F-7.4-03/R0)']);
    rows.add(['Rating Period:', period]);
    rows.add([]);
    rows.add([
      'Sl No',
      'ID No',
      'Vendor / Supplier Name',
      'Qty Recd',
      'Qty Rej',
      'QR (Max 70)',
      'Delay (Days)',
      'DR (Max 30)',
      'Total (Max 100)',
      'Grade',
      'Remarks',
    ]);

    for (int i = 0; i < suppliers.length; i++) {
      final s = suppliers[i];
      final r = ratingsMap[s.id];
      final qrStr = r?.qr?.toString() ?? '-';
      final drStr = r?.dr?.toString() ?? '-';
      final totalStr = r?.total?.toString() ?? '-';
      final gradeStr = RatingCalculator.getGrade(r?.total) ?? '-';

      rows.add([
        i + 1,
        s.id,
        s.name,
        r?.qtyReceived?.toString() ?? '',
        r?.qtyRejected?.toString() ?? '',
        qrStr,
        r?.delayDays?.toString() ?? '',
        drStr,
        totalStr,
        gradeStr,
        r?.remarks ?? '',
      ]);
    }

    rows.add([]);
    rows.add([
      '',
      '',
      'Average Total Score:',
      '',
      '',
      '',
      '',
      '',
      averageTotal != null ? averageTotal.toStringAsFixed(1) : '-',
      '',
      '',
    ]);

    final csvData = convertToCsv(rows);
    FileDownloader.downloadTextFile(
      content: csvData,
      fileName: 'Supplier_Ratings_$period.csv',
    );
  }

  /// Export Ratings to PDF replicating F-7.4-03/R0
  static Future<void> exportRatingsToPdf({
    required String period,
    required List<Supplier> suppliers,
    required Map<String, Rating> ratingsMap,
    required double? averageTotal,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MANUFACTURING OPERATIONS - PURCHASE DEPARTMENT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'SUPPLIER RATING FORM',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'Assessment Period: Financial Year $period (April - March)',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.blueGrey700,
                        width: 1,
                      ),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Format No: F-7.4-03/R0',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Row(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Prepared By: Purchase In-Charge',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            '(Signature & Date)',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(width: 50),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Approved By: Director',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            '(Signature & Date)',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 3.5,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // Sl No
                1: const pw.FixedColumnWidth(46), // ID
                2: const pw.FlexColumnWidth(3), // Vendor
                3: const pw.FixedColumnWidth(50), // Recd
                4: const pw.FixedColumnWidth(48), // Rej
                5: const pw.FixedColumnWidth(48), // QR
                6: const pw.FixedColumnWidth(48), // Delay
                7: const pw.FixedColumnWidth(48), // DR
                8: const pw.FixedColumnWidth(52), // Total
                9: const pw.FixedColumnWidth(60), // Grade
                10: const pw.FlexColumnWidth(2.5), // Remarks
              },
              headers: [
                'Sl',
                'ID No',
                'Vendor Name',
                'Qty Recd',
                'Qty Rej',
                'QR (70)',
                'Delay',
                'DR (30)',
                'Total',
                'Grade',
                'Remarks',
              ],
              data: suppliers.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final s = entry.value;
                final r = ratingsMap[s.id];
                final qrStr = r?.qr?.toString() ?? '-';
                final drStr = r?.dr?.toString() ?? '-';
                final totalStr = r?.total?.toString() ?? '-';
                final gradeStr = RatingCalculator.getGrade(r?.total) ?? '-';

                return [
                  i.toString(),
                  s.id,
                  s.name,
                  r?.qtyReceived?.toString() ?? '-',
                  r?.qtyRejected?.toString() ?? '-',
                  qrStr,
                  r?.delayDays != null ? '${r!.delayDays} d' : '-',
                  drStr,
                  totalStr,
                  gradeStr,
                  r?.remarks ?? '-',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 10),

            // Summary row & Reference table
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Average Total Score: ${averageTotal != null ? "${averageTotal.toStringAsFixed(1)} / 100" : "-"}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Grading Scale: >=90 Excellent | 80-89 Good | 60-79 Average | <60 Poor (Review)',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  width: 320,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Delivery Rating (DR) Formula Reference:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.5,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Delay: 0d -> 100% (30) | 1-2d -> 90% (27) | 3-4d -> 80% (24) | 5-6d -> 60% (18)\n7-8d -> 55% (17) | 9-10d -> 50% (15) | 11-12d -> 40% (12) | 13-15d -> 30% (9)\n16-20d -> 20% (6) | >20d -> 0% (0)',
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Supplier_Ratings_$period.pdf',
    );
  }
}
