// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import '../models/contact_person.dart';
import '../providers/supplier_provider.dart';
import '../theme/app_theme.dart';

class SupplierRegistrationScreen extends StatefulWidget {
  const SupplierRegistrationScreen({super.key});

  @override
  State<SupplierRegistrationScreen> createState() =>
      _SupplierRegistrationScreenState();
}

class _SupplierRegistrationScreenState
    extends State<SupplierRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Category
  String _category = 'Spare Parts';
  static const List<String> _categories = [
    'Fixed Assets',
    'Spare Parts',
    'Consumables',
    'Services',
  ];

  // Basic Information
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _factoryAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _faxController = TextEditingController();
  final _emailController = TextEditingController();
  final _yearEstController = TextEditingController();

  // Nature of Business
  String _natureOfBusiness = 'Manufacturer';
  final _dealerForController = TextEditingController();

  // Management
  final _mdNameController = TextEditingController();

  // Dynamic Contact Persons (min 1)
  final List<_ContactRowControllers> _contactControllers = [];

  // Capabilities & Quality
  final _productRangeController = TextEditingController();
  final _otherFirmController = TextEditingController();
  final _qcSystemController = TextEditingController();

  // Manpower
  final _qualifiedController = TextEditingController();
  final _skilledController = TextEditingController();
  final _unskilledController = TextEditingController();

  // Commercial
  final _machineryController = TextEditingController();
  final _turnoverController = TextEditingController();
  final _gstController = TextEditingController();
  final _bankersController = TextEditingController();
  final _customersController = TextEditingController();

  // Evaluation & Approvals
  String _evaluationMethod = 'On-site';
  String _purchaseMethod = 'With PO';
  bool _recommended = true;

  final _preparedByController = TextEditingController(
    text: 'Purchase In-Charge',
  );
  String _approvedBy = 'Director';
  static const List<String> _directors = [
    'Director',
    'Dr. K. N. Rao (Director)',
    'Managing Director',
    'Executive Director',
    'Director (Operations)',
    'Director (Technical)',
  ];

  bool _isSubmitting = false;
  String? _duplicateErrorMessage;

  @override
  void initState() {
    super.initState();
    _addContactPersonRow();
  }

  void _addContactPersonRow() {
    setState(() {
      _contactControllers.add(_ContactRowControllers());
    });
  }

  void _removeContactPersonRow(int index) {
    if (_contactControllers.length > 1) {
      setState(() {
        final row = _contactControllers.removeAt(index);
        row.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one contact person is required.'),
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _addressController.clear();
    _factoryAddressController.clear();
    _phoneController.clear();
    _faxController.clear();
    _emailController.clear();
    _yearEstController.clear();
    _dealerForController.clear();
    _mdNameController.clear();
    _productRangeController.clear();
    _otherFirmController.clear();
    _qcSystemController.clear();
    _qualifiedController.clear();
    _skilledController.clear();
    _unskilledController.clear();
    _machineryController.clear();
    _turnoverController.clear();
    _gstController.clear();
    _bankersController.clear();
    _customersController.clear();
    _preparedByController.text = 'Purchase In-Charge';

    for (final c in _contactControllers) {
      c.dispose();
    }
    _contactControllers.clear();
    _addContactPersonRow();

    setState(() {
      _category = 'Spare Parts';
      _natureOfBusiness = 'Manufacturer';
      _evaluationMethod = 'On-site';
      _purchaseMethod = 'With PO';
      _recommended = true;
      _approvedBy = 'Director';
      _duplicateErrorMessage = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _factoryAddressController.dispose();
    _phoneController.dispose();
    _faxController.dispose();
    _emailController.dispose();
    _yearEstController.dispose();
    _dealerForController.dispose();
    _mdNameController.dispose();
    _productRangeController.dispose();
    _otherFirmController.dispose();
    _qcSystemController.dispose();
    _qualifiedController.dispose();
    _skilledController.dispose();
    _unskilledController.dispose();
    _machineryController.dispose();
    _turnoverController.dispose();
    _gstController.dispose();
    _bankersController.dispose();
    _customersController.dispose();
    _preparedByController.dispose();
    for (final c in _contactControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _duplicateErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors in the form.'),
          backgroundColor: AppTheme.notRecommendedRed,
        ),
      );
      return;
    }

    final supplierProvider = context.read<SupplierProvider>();

    // Duplicate verification
    final duplicateErr = supplierProvider.checkForDuplicate(
      name: _nameController.text,
      gstNo: _gstController.text,
    );
    if (duplicateErr != null) {
      setState(() {
        _duplicateErrorMessage = duplicateErr;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final contacts = _contactControllers.map((c) {
        return ContactPerson(
          name: c.name.text.trim(),
          designation: c.designation.text.trim(),
          phone: c.phone.text.trim(),
        );
      }).toList();

      final created = await supplierProvider.registerSupplier(
        category: _category,
        name: _nameController.text,
        address: _addressController.text,
        factoryAddress: _factoryAddressController.text,
        phone: _phoneController.text,
        fax: _faxController.text,
        email: _emailController.text,
        yearEstablished: int.tryParse(_yearEstController.text),
        natureOfBusiness: _natureOfBusiness,
        dealerFor: _dealerForController.text,
        mdName: _mdNameController.text,
        contacts: contacts,
        productRange: _productRangeController.text,
        otherFirmAssessment: _otherFirmController.text,
        qcSystem: _qcSystemController.text,
        manpowerQualified: int.tryParse(_qualifiedController.text),
        manpowerSkilled: int.tryParse(_skilledController.text),
        manpowerUnskilled: int.tryParse(_unskilledController.text),
        machinery: _machineryController.text,
        annualTurnover: _turnoverController.text,
        gstNo: _gstController.text,
        bankers: _bankersController.text,
        majorCustomers: _customersController.text,
        evaluationMethod: _evaluationMethod,
        purchaseMethod: _purchaseMethod,
        recommended: _recommended,
        preparedBy: _preparedByController.text,
        approvedBy: _approvedBy,
      );

      if (!mounted) return;

      // Show success dialog with ID
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.approvedGreen, size: 28),
              SizedBox(width: 10),
              Text('Registration Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supplier "${created.name}" has been registered successfully.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assigned Supplier ID:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      created.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Status: Pending approval (a consultant or admin must approve this request)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.temporaryAmber,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go(AppRoutes.customerDashboard);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _duplicateErrorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Supplier Registration Form',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Form R/PUR-03 · Initial Vendor Assessment & Master Data Entry',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: const Text(
                        'Format: R/PUR-03',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Duplicate Error Alert (if any)
                if (_duplicateErrorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.notRecommendedRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.notRecommendedRed,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _duplicateErrorMessage!,
                            style: const TextStyle(
                              color: AppTheme.notRecommendedRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. General & Classification
                _formSection(
                  title: '1. Classification & Basic Details',
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category*',
                        helperText: 'Select supplier material category',
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name of Supplier*',
                        hintText: 'e.g. Apex Precision Tools Pvt Ltd',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Supplier name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address*',
                        hintText: 'Full registered business address',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Registered address is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _factoryAddressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Office / Factory Address (if separate)',
                        hintText:
                            'Plant or works location if distinct from head office',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telephone*',
                              hintText: 'e.g. 080-28394451 or 9845012345',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Telephone is required.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _faxController,
                            decoration: const InputDecoration(
                              labelText: 'Fax',
                              hintText: 'e.g. 080-28394452',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'e.g. info@supplier.com',
                            ),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(val.trim())) {
                                  return 'Enter a valid email address.';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _yearEstController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Year of Establishment',
                              hintText: 'e.g. 2010',
                            ),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                final year = int.tryParse(val.trim());
                                final currentYear = DateTime.now().year;
                                if (year == null ||
                                    val.trim().length != 4 ||
                                    year > currentYear ||
                                    year < 1850) {
                                  return 'Enter valid 4-digit year up to $currentYear.';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nature of Business',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Manufacturer',
                                    groupValue: _natureOfBusiness,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _natureOfBusiness = val);
                                      }
                                    },
                                  ),
                                  const Text('Manufacturer'),
                                  const SizedBox(width: 16),
                                  Radio<String>(
                                    value: 'Dealer',
                                    groupValue: _natureOfBusiness,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _natureOfBusiness = val);
                                      }
                                    },
                                  ),
                                  const Text('Dealer'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_natureOfBusiness == 'Dealer') ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _dealerForController,
                              decoration: const InputDecoration(
                                labelText: 'Dealer for (brands)*',
                                hintText: 'e.g. Mitutoyo, Kennametal, Addison',
                              ),
                              validator: (val) {
                                if (_natureOfBusiness == 'Dealer' &&
                                    (val == null || val.trim().isEmpty)) {
                                  return 'Specify brands represented.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mdNameController,
                      decoration: const InputDecoration(
                        labelText:
                            'Name & Address of Managing Partner / MD / CEO',
                        hintText: 'Key decision maker name and designation',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Contact Persons (Dynamic List)
                _formSection(
                  title: '2. Contact Persons (Minimum 1 Required)',
                  actions: [
                    TextButton.icon(
                      onPressed: _addContactPersonRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Contact Person'),
                    ),
                  ],
                  children: [
                    ..._contactControllers.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFFCBD5E1),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: row.name,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Name*',
                                    isDense: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: row.designation,
                                  decoration: const InputDecoration(
                                    labelText: 'Designation*',
                                    isDense: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: row.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Telephone / Fax*',
                                    isDense: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_contactControllers.length > 1) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.notRecommendedRed,
                                    size: 20,
                                  ),
                                  tooltip: 'Remove contact person',
                                  onPressed: () => _removeContactPersonRow(idx),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Technical Capabilities & Quality System
                _formSection(
                  title: '3. Technical Scope & Quality Systems',
                  children: [
                    TextFormField(
                      controller: _productRangeController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Product Range / Items Supplied*',
                        hintText: 'Complete list or scope of items offered',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Product range / items supplied is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otherFirmController,
                      decoration: const InputDecoration(
                        labelText: 'Assessment by any other firm (details)',
                        hintText: 'e.g. Approved vendor for HAL, BHEL, Toyota',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _qcSystemController,
                      decoration: const InputDecoration(
                        labelText: 'Quality Control System Followed',
                        hintText:
                            'e.g. ISO 9001:2015, IATF 16949, In-house inspection lab',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Manpower, Machinery & Commercials
                _formSection(
                  title: '4. Manpower, Machinery & Commercial Details',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qualifiedController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Manpower: Qualified',
                              hintText: 'Numbers only',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _skilledController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Manpower: Skilled',
                              hintText: 'Numbers only',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _unskilledController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Manpower: Unskilled',
                              hintText: 'Numbers only',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _machineryController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Machinery Details',
                        hintText:
                            'Key production equipment, CNC machines, measuring apparatus',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _turnoverController,
                            decoration: const InputDecoration(
                              labelText: 'Annual Turnover (Rs.)',
                              hintText: 'e.g. 5.50 Crores',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _gstController,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'GST Reg. No. (15 characters)',
                              hintText: 'e.g. 29ABCDE1234F1Z5',
                            ),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                final clean = val.trim().toUpperCase();
                                // 15-char GSTIN regex
                                final gstRegex = RegExp(
                                  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                                );
                                if (!gstRegex.hasMatch(clean)) {
                                  return 'Invalid GST format (15 alphanumeric characters e.g. 29AABCS1429B1Z8).';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bankersController,
                            decoration: const InputDecoration(
                              labelText: 'Name of Bankers',
                              hintText: 'e.g. SBI, Industrial Finance Branch',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _customersController,
                            decoration: const InputDecoration(
                              labelText: 'Existing Major Customers',
                              hintText: 'e.g. Bharat Forge, Titan, Tata Motors',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Evaluation, Purchase & Recommendations
                _formSection(
                  title: '5. Evaluation Method & Inclusion Recommendation',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Evaluation Method',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: 'On-site',
                                        groupValue: _evaluationMethod,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _evaluationMethod = val,
                                            );
                                          }
                                        },
                                      ),
                                      const Text('On-site'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: 'Sample',
                                        groupValue: _evaluationMethod,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _evaluationMethod = val,
                                            );
                                          }
                                        },
                                      ),
                                      const Text('Sample'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: 'Based on Brand',
                                        groupValue: _evaluationMethod,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _evaluationMethod = val,
                                            );
                                          }
                                        },
                                      ),
                                      const Text('Based on Brand'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _purchaseMethod,
                            decoration: const InputDecoration(
                              labelText: 'Method of Purchase',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'With PO',
                                child: Text('With PO'),
                              ),
                              DropdownMenuItem(
                                value: 'Verbal',
                                child: Text('Verbal'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _purchaseMethod = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _recommended
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _recommended
                              ? AppTheme.approvedGreen.withValues(alpha: 0.3)
                              : AppTheme.notRecommendedRed.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommended for inclusion in ASL based on verification/visit?*',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Radio<bool>(
                                    value: true,
                                    groupValue: _recommended,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _recommended = val);
                                      }
                                    },
                                  ),
                                  const Text(
                                    'Yes (Approved for ASL)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Row(
                                children: [
                                  Radio<bool>(
                                    value: false,
                                    groupValue: _recommended,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _recommended = val);
                                      }
                                    },
                                  ),
                                  const Text(
                                    'No (Not Recommended)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _preparedByController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Signature of Purchase In-charge (Name)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _approvedBy,
                            decoration: const InputDecoration(
                              labelText: 'Approved by Director (Name)',
                            ),
                            items: _directors
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _approvedBy = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _resetForm,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset Form'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isSubmitting
                            ? 'Generating ID & Saving...'
                            : 'Submit Supplier Registration',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formSection({
    required String title,
    List<Widget>? actions,
    required List<Widget> children,
  }) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.primaryLight,
                  ),
                ),
                if (actions != null) Row(children: actions),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ContactRowControllers {
  final TextEditingController name = TextEditingController();
  final TextEditingController designation = TextEditingController();
  final TextEditingController phone = TextEditingController();

  void dispose() {
    name.dispose();
    designation.dispose();
    phone.dispose();
  }
}
