import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class SupplierDetailModal extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback? onDelete;

  const SupplierDetailModal({super.key, required this.supplier, this.onDelete});

  static void show(
    BuildContext context,
    Supplier supplier, {
    VoidCallback? onDelete,
  }) {
    showDialog(
      context: context,
      builder: (ctx) =>
          SupplierDetailModal(supplier: supplier, onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      supplier.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Text(
                          'Supplier Registration Record · R/PUR-03',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: supplier.status),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('General & Contact Information'),
                    _infoGrid([
                      _item('Category', supplier.category),
                      _item('Date of Inclusion', supplier.dateOfInclusion),
                      _item('Telephone', supplier.phone),
                      _item('Fax', supplier.fax ?? '-'),
                      _item('Email', supplier.email ?? '-'),
                      _item(
                        'Year Established',
                        supplier.yearEstablished?.toString() ?? '-',
                      ),
                      _item('Nature of Business', supplier.natureOfBusiness),
                      if (supplier.dealerFor != null &&
                          supplier.dealerFor!.isNotEmpty)
                        _item('Dealer For Brands', supplier.dealerFor!),
                      _item('MD / Managing Partner', supplier.mdName ?? '-'),
                    ]),
                    const SizedBox(height: 12),
                    _itemFull('Registered Address', supplier.address),
                    if (supplier.factoryAddress != null &&
                        supplier.factoryAddress!.isNotEmpty)
                      _itemFull(
                        'Office / Factory Address',
                        supplier.factoryAddress!,
                      ),

                    const Divider(height: 32),
                    _sectionTitle('Contact Persons'),
                    if (supplier.contacts.isEmpty)
                      const Text(
                        'No contact persons recorded.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                              ),
                              children: [
                                _tableHeader('Name'),
                                _tableHeader('Designation'),
                                _tableHeader('Telephone / Fax'),
                              ],
                            ),
                            ...supplier.contacts.map(
                              (c) => TableRow(
                                children: [
                                  _tableCell(c.name),
                                  _tableCell(c.designation),
                                  _tableCell(c.phone),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Divider(height: 32),
                    _sectionTitle('Capabilities & Quality Systems'),
                    _itemFull(
                      'Product Range / Items Supplied',
                      supplier.productRange,
                    ),
                    _itemFull(
                      'Quality Control System',
                      supplier.qcSystem ?? 'Not specified',
                    ),
                    _itemFull(
                      'Machinery Details',
                      supplier.machinery ?? 'Not specified',
                    ),
                    _itemFull(
                      'Assessment by Other Firms',
                      supplier.otherFirmAssessment ?? 'None / Not documented',
                    ),

                    const SizedBox(height: 12),
                    _infoGrid([
                      _item(
                        'Qualified Manpower',
                        supplier.manpowerQualified?.toString() ?? '-',
                      ),
                      _item(
                        'Skilled Manpower',
                        supplier.manpowerSkilled?.toString() ?? '-',
                      ),
                      _item(
                        'Unskilled Manpower',
                        supplier.manpowerUnskilled?.toString() ?? '-',
                      ),
                      _item('Annual Turnover', supplier.annualTurnover ?? '-'),
                      _item('GST Reg. No.', supplier.gstNo ?? '-'),
                      _item('Bankers', supplier.bankers ?? '-'),
                    ]),
                    _itemFull(
                      'Major Customers',
                      supplier.majorCustomers ?? 'Not documented',
                    ),

                    const Divider(height: 32),
                    _sectionTitle('Evaluation & Approval Details'),
                    _infoGrid([
                      _item('Evaluation Method', supplier.evaluationMethod),
                      _item('Method of Purchase', supplier.purchaseMethod),
                      _item(
                        'Recommended for ASL',
                        supplier.recommended ? 'YES' : 'NO',
                      ),
                      _item(
                        'Purchase In-charge Signature',
                        supplier.preparedBy ?? '-',
                      ),
                      _item('Approved by Director', supplier.approvedBy ?? '-'),
                    ]),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onDelete != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.notRecommendedRed,
                        side: const BorderSide(
                          color: AppTheme.notRecommendedRed,
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete Supplier'),
                      onPressed: onDelete,
                    )
                  else
                    const SizedBox(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppTheme.primaryLight,
        ),
      ),
    );
  }

  Widget _infoGrid(List<Widget> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: items.map((item) => SizedBox(width: 220, child: item)).toList(),
    );
  }

  Widget _item(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _itemFull(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  static Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
      ),
    );
  }
}
