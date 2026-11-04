import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../providers/rating_provider.dart';
import '../providers/supplier_provider.dart';
import '../services/export_service.dart';
import '../services/rating_calculator.dart';
import '../theme/app_theme.dart';
import '../widgets/grade_badge.dart';
import '../widgets/rating_bar_chart.dart';
import '../widgets/rating_formula_card.dart';

class SupplyRatingScreen extends StatefulWidget {
  const SupplyRatingScreen({super.key});

  @override
  State<SupplyRatingScreen> createState() => _SupplyRatingScreenState();
}

class _SupplyRatingScreenState extends State<SupplyRatingScreen> {
  bool _initialized = false;
  final Map<String, TextEditingController> _qtyRecdControllers = {};
  final Map<String, TextEditingController> _qtyRejControllers = {};
  final Map<String, TextEditingController> _delayControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final approvedSuppliers = context
          .read<SupplierProvider>()
          .approvedSuppliers;
      final ratingProvider = context.read<RatingProvider>();
      ratingProvider
          .loadRatingsForPeriod(
            ratingProvider.selectedPeriod,
            approvedSuppliers,
          )
          .then((_) => _syncControllers(approvedSuppliers));
    }
  }

  void _syncControllers(List<Supplier> approvedSuppliers) {
    final ratingProvider = context.read<RatingProvider>();
    for (final s in approvedSuppliers) {
      final r = ratingProvider.getRating(s.id);

      _qtyRecdControllers.putIfAbsent(
        s.id,
        () => TextEditingController(text: r?.qtyReceived?.toString() ?? ''),
      );
      _qtyRejControllers.putIfAbsent(
        s.id,
        () => TextEditingController(text: r?.qtyRejected?.toString() ?? ''),
      );
      _delayControllers.putIfAbsent(
        s.id,
        () => TextEditingController(text: r?.delayDays?.toString() ?? ''),
      );
      _remarksControllers.putIfAbsent(
        s.id,
        () => TextEditingController(text: r?.remarks ?? ''),
      );

      // Update text in case period was switched
      _qtyRecdControllers[s.id]!.text = r?.qtyReceived?.toString() ?? '';
      _qtyRejControllers[s.id]!.text = r?.qtyRejected?.toString() ?? '';
      _delayControllers[s.id]!.text = r?.delayDays?.toString() ?? '';
      _remarksControllers[s.id]!.text = r?.remarks ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in _qtyRecdControllers.values) {
      c.dispose();
    }
    for (final c in _qtyRejControllers.values) {
      c.dispose();
    }
    for (final c in _delayControllers.values) {
      c.dispose();
    }
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handlePeriodChange(String newPeriod) async {
    final approvedSuppliers = context
        .read<SupplierProvider>()
        .approvedSuppliers;
    final ratingProvider = context.read<RatingProvider>();
    await ratingProvider.loadRatingsForPeriod(newPeriod, approvedSuppliers);
    _syncControllers(approvedSuppliers);
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final ratingProvider = context.watch<RatingProvider>();

    // Auto-fetch: pull every supplier with Status = Approved from suppliers collection
    final approvedSuppliers = supplierProvider.approvedSuppliers;
    final averageTotal = ratingProvider.getAverageTotal();
    final availablePeriods = RatingProvider.getAvailablePeriods();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Supplier Rating Form',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Quality & Delivery Evaluation',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'F-7.4-03/R0 · Live performance assessment: Quality Rating (70) + Delivery Rating (30)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),

                  // Actions: Save & Export
                  Wrap(
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 18,
                        ),
                        label: const Text('Export CSV'),
                        onPressed: approvedSuppliers.isEmpty
                            ? null
                            : () => ExportService.exportRatingsToCsv(
                                period: ratingProvider.selectedPeriod,
                                suppliers: approvedSuppliers,
                                ratingsMap: {
                                  for (var s in approvedSuppliers)
                                    s.id: ratingProvider.getRating(s.id)!,
                                },
                                averageTotal: averageTotal,
                              ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18,
                        ),
                        label: const Text('Export PDF (F-7.4-03)'),
                        onPressed: approvedSuppliers.isEmpty
                            ? null
                            : () => ExportService.exportRatingsToPdf(
                                period: ratingProvider.selectedPeriod,
                                suppliers: approvedSuppliers,
                                ratingsMap: {
                                  for (var s in approvedSuppliers)
                                    s.id: ratingProvider.getRating(s.id)!,
                                },
                                averageTotal: averageTotal,
                              ),
                      ),
                      ElevatedButton.icon(
                        icon: ratingProvider.isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          ratingProvider.isSaving
                              ? 'Saving Ratings...'
                              : 'Save Ratings',
                        ),
                        onPressed: ratingProvider.isSaving
                            ? null
                            : () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                await ratingProvider.saveAllRatings();
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'All ratings for ${ratingProvider.selectedPeriod} saved successfully.',
                                    ),
                                    backgroundColor: AppTheme.approvedGreen,
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Rating Period Selector & Summary Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Financial Year Dropdown
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Rating Period (Financial Year):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ratingProvider.selectedPeriod,
                            items: availablePeriods
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      'FY $p (April - March)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                _handlePeriodChange(val);
                              }
                            },
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Average Total Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Average Total Score: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              averageTotal != null
                                  ? '${averageTotal.toStringAsFixed(1)} / 100'
                                  : '- / 100',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rating Table
              if (approvedSuppliers.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 44,
                          color: AppTheme.temporaryAmber,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No approved suppliers found.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Only suppliers with status "Approved" in the supplier repository are evaluated here.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 1250),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        horizontalMargin: 16,
                        columnSpacing: 14,
                        dataRowMinHeight: 70,
                        dataRowMaxHeight: 80,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Sl No',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Vendor / Supplier Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Qty Recd',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Qty Rej',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'QR (Max 70)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Delay (Days)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'DR (Max 30)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Total (100)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Grade',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Remarks / Action Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Non-Existing',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        rows: approvedSuppliers.asMap().entries.map((entry) {
                          final slNo = entry.key + 1;
                          final s = entry.value;
                          final r = ratingProvider.getRating(s.id);

                          // Ensure controllers exist
                          _qtyRecdControllers.putIfAbsent(
                            s.id,
                            () => TextEditingController(
                              text: r?.qtyReceived?.toString() ?? '',
                            ),
                          );
                          _qtyRejControllers.putIfAbsent(
                            s.id,
                            () => TextEditingController(
                              text: r?.qtyRejected?.toString() ?? '',
                            ),
                          );
                          _delayControllers.putIfAbsent(
                            s.id,
                            () => TextEditingController(
                              text: r?.delayDays?.toString() ?? '',
                            ),
                          );
                          _remarksControllers.putIfAbsent(
                            s.id,
                            () => TextEditingController(text: r?.remarks ?? ''),
                          );

                          // Keep remarks input in sync if updated automatically by calculator
                          if (r?.remarks != null &&
                              _remarksControllers[s.id]!.text != r!.remarks) {
                            _remarksControllers[s.id]!.text = r.remarks!;
                          }

                          final qrText = r?.qr != null ? '${r!.qr}' : '-';
                          final drText = r?.dr != null ? '${r!.dr}' : '-';
                          final totalText = r?.total != null
                              ? '${r!.total}'
                              : '-';
                          final grade = RatingCalculator.getGrade(r?.total);

                          final isNonExisting =
                              r?.remarks?.contains('NON-EXISTING') == true;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '$slNo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: ${s.id} · ${s.category}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Qty Received Input
                              DataCell(
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    controller: _qtyRecdControllers[s.id],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final numVal = num.tryParse(val.trim());
                                      ratingProvider.updateQtyReceived(
                                        s.id,
                                        numVal,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Qty Rejected Input
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _qtyRejControllers[s.id],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final numVal = num.tryParse(val.trim());
                                      ratingProvider.updateQtyRejected(
                                        s.id,
                                        numVal,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Quality Rating (QR max 70)
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    qrText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              // Delay in Days Input
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _delayControllers[s.id],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final intVal = int.tryParse(val.trim());
                                      ratingProvider.updateDelayDays(
                                        s.id,
                                        intVal,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Delivery Rating (DR max 30)
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    drText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              // TOTAL (Max 100)
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: r?.total != null
                                        ? AppTheme.primaryColor.withValues(
                                            alpha: 0.1,
                                          )
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    totalText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: r?.total != null
                                          ? AppTheme.primaryColor
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              // Grade Badge
                              DataCell(GradeBadge(grade: grade)),
                              // Remarks Input
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: TextFormField(
                                    controller: _remarksControllers[s.id],
                                    decoration: const InputDecoration(
                                      hintText: 'Enter remarks...',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      ratingProvider.updateRemarks(
                                        s.id,
                                        val.trim(),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Non-Existing Toggle
                              DataCell(
                                Switch(
                                  value: isNonExisting,
                                  activeThumbColor: AppTheme.notRecommendedRed,
                                  onChanged: (val) async {
                                    await ratingProvider.toggleNonExisting(
                                      s.id,
                                      val,
                                      supplierProvider,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Bar Chart Visualization
              RatingBarChart(
                suppliers: approvedSuppliers,
                ratingsMap: {
                  for (var s in approvedSuppliers)
                    s.id: ratingProvider.getRating(s.id)!,
                },
              ),
              const SizedBox(height: 24),

              // Reference Formula Card
              const RatingFormulaCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
