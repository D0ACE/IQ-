import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

class AssignNextVisitDialog extends StatefulWidget {
  final CustomerModel customer;

  const AssignNextVisitDialog({
    super.key,
    required this.customer,
  });

  @override
  State<AssignNextVisitDialog> createState() =>
      _AssignNextVisitDialogState();
}

class _AssignNextVisitDialogState extends State<AssignNextVisitDialog> {
  DateTime? selectedDate;
  final TextEditingController dateController = TextEditingController();

  final DateFormat formatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();

    /// ✅ If nextVisitDate already exists (STRING) → show it
    if (widget.customer.nextVisitDate != null &&
        widget.customer.nextVisitDate!.isNotEmpty) {
      selectedDate =
          formatter.parse(widget.customer.nextVisitDate!);
      dateController.text = widget.customer.nextVisitDate!;
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        dateController.text = formatter.format(date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Next Visit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Customer Name
          const Text(
            'Customer Name',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            widget.customer.companyName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          /// Date Field
          TextField(
            controller: dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Next Visit Date',
              hintText: 'Select date',
              suffixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            onTap: pickDate,
          ),

          const SizedBox(height: 20),

          /// ✅ Submit Button → RETURN STRING
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (dateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select date'),
                    ),
                  );
                  return;
                }

                /// ✅ Return STRING date
                Navigator.pop(context, dateController.text);
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
