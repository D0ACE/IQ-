import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'grade_badge.dart';

class RatingFormulaCard extends StatelessWidget {
  const RatingFormulaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 18,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Form F-7.4-03/R0 Rating Reference & Standard Calculation Formula',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 750;
                if (isCompact) {
                  return Column(
                    children: [
                      _qrFormulaBox(),
                      const SizedBox(height: 16),
                      _drTableBox(),
                      const SizedBox(height: 16),
                      _gradesBox(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _qrFormulaBox(),
                          const SizedBox(height: 16),
                          _gradesBox(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: _drTableBox()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrFormulaBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '1. QUALITY RATING (QR) - MAX 70',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'QR = 70 × (Qty Received - Qty Rejected) / Qty Received',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Rounded to nearest whole number. If no supply received in period, marked as "-" and omitted from averages.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _drTableBox() {
    final rows = [
      {'delay': '0 days', 'pct': '100%', 'dr': '30'},
      {'delay': '1 - 2 days', 'pct': '90%', 'dr': '27'},
      {'delay': '3 - 4 days', 'pct': '80%', 'dr': '24'},
      {'delay': '5 - 6 days', 'pct': '60%', 'dr': '18'},
      {'delay': '7 - 8 days', 'pct': '55%', 'dr': '17'},
      {'delay': '9 - 10 days', 'pct': '50%', 'dr': '15'},
      {'delay': '11 - 12 days', 'pct': '40%', 'dr': '12'},
      {'delay': '13 - 15 days', 'pct': '30%', 'dr': '9'},
      {'delay': '16 - 20 days', 'pct': '20%', 'dr': '6'},
      {'delay': '> 20 days', 'pct': '0%', 'dr': '0'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2. DELIVERY RATING (DR) - MAX 30 (DR = 30 × % / 100)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: AppTheme.borderColor),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Delay in Days',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Delivery %',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'DR Score',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              ...rows.map(
                (r) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        r['delay']!,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        r['pct']!,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        r['dr']!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradesBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. TOTAL SCORE (MAX 100 = QR + DR) & PERFORMANCE GRADES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _GradeLegendItem(grade: 'Excellent', range: 'Score: 90 - 100'),
              _GradeLegendItem(grade: 'Good', range: 'Score: 80 - 89'),
              _GradeLegendItem(grade: 'Average', range: 'Score: 60 - 79'),
              _GradeLegendItem(
                grade: 'Poor / Review',
                range: 'Score: < 60 (Action required)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeLegendItem extends StatelessWidget {
  final String grade;
  final String range;

  const _GradeLegendItem({required this.grade, required this.range});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GradeBadge(grade: grade),
        const SizedBox(width: 6),
        Text(
          range,
          style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
        ),
      ],
    );
  }
}
