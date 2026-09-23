import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:iq_plus/features/superadmin/models/document_model.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:excel_plus/excel_plus.dart' as excel_pkg;
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ExcelEditorPage extends StatefulWidget {
  final DocumentModel? document;
  const ExcelEditorPage({super.key, this.document});

  @override
  State<ExcelEditorPage> createState() => _ExcelEditorPageState();
}

class _ExcelEditorPageState extends State<ExcelEditorPage> {
  PlutoGridStateManager? stateManager;
  List<PlutoColumn> columns = [];
  List<PlutoRow> rows = [];
  bool _isLoading = true;
  final titleCtrl = TextEditingController();
  final changeDescriptionCtrl = TextEditingController();
  String? selectedCustomerId;
  bool _isGridDirty = false; // 👈 Track content changes
  final _currentUser = getIt<HiveService>().getUser();

  // 🔄 Re-upload support
  Uint8List? selectedFileBytes;
  String? selectedFileName;

  @override
  void initState() {
    super.initState();
    // context.read<CustomerListCubit>().fetchCustomers(); // Managed by widget
    
    if (widget.document != null) {
      titleCtrl.text = widget.document!.title;
      selectedCustomerId = widget.document!.customerId;
      _loadExcelData();
    } else {
      _initEmptyGrid();
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    changeDescriptionCtrl.dispose();
    super.dispose();
  }

  void _initEmptyGrid() {
    columns = List.generate(5, (i) => PlutoColumn(
      title: 'Col ${i + 1}',
      field: 'col$i',
      type: PlutoColumnType.text(),
      width: 150,
    ));
    
    rows = List.generate(10, (i) => PlutoRow(
      cells: { for (var j=0; j<5; j++) 'col$j' : PlutoCell(value: '') },
    ));
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadExcelData() async {
    try {
      final response = await http.get(Uri.parse(widget.document!.fileUrl));
      final bytes = response.bodyBytes;
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table != null) {
        final int maxCols = table.maxColumns;
        
        List<PlutoColumn> loadedColumns = [];
        List<PlutoRow> loadedRows = [];

        // 1. Build Columns
        for (int i = 0; i < maxCols; i++) {
          loadedColumns.add(PlutoColumn(
            title: 'Col ${i + 1}',
            field: 'col$i',
            type: PlutoColumnType.text(),
            width: 150,
            readOnly: widget.document != null, // 🚀 Read-only for uploaded files
          ));
        }

        // 2. Build Rows
        for (var excelRow in table.rows) {
          Map<String, PlutoCell> cells = {};
          for (int i = 0; i < maxCols; i++) {
            final val = i < excelRow.length ? excelRow[i]?.value?.toString() ?? "" : "";
            cells['col$i'] = PlutoCell(value: val);
          }
          loadedRows.add(PlutoRow(cells: cells));
        }

        setState(() {
          columns = loadedColumns;
          rows = loadedRows;
        });

      } else {
        _initEmptyGrid();
      }
    } catch (e) {
      developer.log("Error loading excel: $e");
      _initEmptyGrid();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImport() async {
    developer.log("📥 Starting Excel Import Process...");
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        developer.log("ℹ️ Import cancelled by user.");
        return;
      }

      setState(() => _isLoading = true);

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        developer.log("❌ Error: File bytes are null.");
        throw Exception("Could not read file bytes");
      }

      developer.log("📊 Decoding file: ${file.name}");
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table != null) {
        setState(() {
          selectedFileBytes = bytes;
          selectedFileName = file.name;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Excel selected. Click Save to upload.")));
        }
      } else {
        developer.log("⚠️ Error: No table found in the decoded Excel file.");
      }
    } catch (e, stackTrace) {
      developer.log("❌ CRITICAL ERROR during Excel import:", error: e, stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import failed: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    developer.log("💾 Starting Excel Policy Save Process...");
    if (titleCtrl.text.trim().isEmpty) {
      developer.log("⚠️ Validation Failed: Policy title is empty.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title")));
      return;
    }

    if (selectedCustomerId == null) {
      developer.log("⚠️ Validation Failed: No customer selected.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a customer")));
      return;
    }

    if (widget.document != null && changeDescriptionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter description of the change")));
      return;
    }
    
    if (widget.document == null && selectedFileBytes == null && stateManager == null) {
      developer.log("⚠️ Error: Grid StateManager is null.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Grid is not initialized")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      Uint8List? finalBytes;

      if (selectedFileBytes != null) {
        // 🚀 Use re-uploaded file bytes
        finalBytes = selectedFileBytes;
      } else if (stateManager != null) {
        // 🚀 Encode grid data to XLSX
        developer.log("📊 Encoding Grid Data to XLSX...");
        final excel = excel_pkg.Excel.createExcel();
        final sheet = excel['Sheet1'];

        for (int rowIndex = 0; rowIndex < stateManager!.rows.length; rowIndex++) {
          final plutoRow = stateManager!.rows[rowIndex];
          for (int colIndex = 0; colIndex < stateManager!.columns.length; colIndex++) {
            final field = stateManager!.columns[colIndex].field;
            final value = plutoRow.cells[field]?.value?.toString() ?? "";
            
            sheet.updateCell(
              excel_pkg.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex),
              excel_pkg.TextCellValue(value),
            );
          }
        }

        final List<int>? fileBytes = excel.encode();
        if (fileBytes != null) {
          finalBytes = Uint8List.fromList(fileBytes);
        }
      }

      if (finalBytes == null && widget.document == null) {
        throw Exception("No content to save");
      }

      developer.log("☁️ Dispatching save command to DocumentCubit...");
      await context.read<DocumentCubit>().saveExcelDocument(
        docId: widget.document?.docId,
        title: titleCtrl.text.trim(),
        bytes: finalBytes ?? Uint8List(0), // Repository handles null/empty if docId exists
        customerId: selectedCustomerId,
        currentFilePath: widget.document?.filePath,
        changeDescription: changeDescriptionCtrl.text.trim(),
        isContentChanged: selectedFileBytes != null || _isGridDirty,
      );

      developer.log("✅ Save Process Completed Successfully.");
      setState(() => _isGridDirty = false); // Reset after save

    } catch (e, stackTrace) {
      developer.log("❌ CRITICAL ERROR during Excel save:", error: e, stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentCubit, DocumentState>(
      listener: (context, state) {
        if (state is DocumentOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          context.pop();
        }
        if (state is DocumentError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          setState(() => _isLoading = false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: CommonAppBar(
          title: widget.document == null ? 'Create Excel Policy' : 'Edit Excel Policy',
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      AppTextFieldWidget(
                        hintText: "Policy Title",
                        textFieldController: titleCtrl,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),

                      if (widget.document != null) ...[
                        AppTextFieldWidget(
                          hintText: "Description of the change",
                          textFieldController: changeDescriptionCtrl,
                          isRequired: true,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      Row(
                        children: [
                          // 👥 Customer Dropdown
                          Expanded(
                            child: CustomerDropdownWidget(
                              hint: "Select Customer *",
                              selectedCustomer: selectedCustomerId != null 
                                  ? CustomerModel(
                                      customerId: selectedCustomerId!,
                                      companyName: '', email: '', phoneNumber: '', password: '', 
                                      certificateStandard: '', numberOfLocations: '', numberOfEmployees: '', 
                                      companyFunction: '', legitDocumentUrl: '', isProfileApproved: true, 
                                      fcmToken: '', roleId: '', createdAt: DateTime.now(), address: '', 
                                      lowLevelName: '', lowLevelEmail: '', lowLevelMobile: '', 
                                      mediumLevelName: '', mediumLevelEmail: '', mediumLevelMobile: '', 
                                      topLevelName: '', topLevelEmail: '', topLevelMobile: ''
                                    )
                                  : null,
                              consultantId: Utility.isConsultant(_currentUser?.roleId) ? _currentUser?.userId : null,
                              onChanged: (customer) {
                                setState(() {
                                  selectedCustomerId = customer?.customerId;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.document != null 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimaryLightColor.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.table_view_rounded, size: 64, color: AppColors.kPrimaryColor),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                selectedFileName ?? widget.document!.fileName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Uploaded Excel Policy",
                                style: TextStyle(color: AppColors.greyTextColor),
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: () => launchUrl(Uri.parse(widget.document!.fileUrl)),
                                icon: const Icon(Icons.download_rounded),
                                label: const Text("Download & View File"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : PlutoGrid(
                          columns: columns,
                          rows: rows,
                          onChanged: (event) => _isGridDirty = true,
                          onLoaded: (event) {
                            stateManager = event.stateManager;
                            stateManager!.setSelectingMode(PlutoGridSelectingMode.cell);
                          },
                          configuration: const PlutoGridConfiguration(
                            style: PlutoGridStyleConfig(
                              gridBorderColor: Colors.transparent,
                              columnTextStyle: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      if (widget.document != null) ...[
                        _actionBtn(Icons.upload_file, "Re-upload", _handleImport, Colors.blue),
                        const SizedBox(width: 8),
                      ],
                      _actionBtn(Icons.save, "SAVE", _handleSave, AppColors.purple),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onPressed, Color color) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
