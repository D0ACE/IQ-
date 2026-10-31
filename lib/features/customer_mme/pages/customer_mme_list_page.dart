import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_state.dart';
import 'package:iq_plus/features/customer_mme/models/mme_model_req.dart';

class CustomerMMEListPage extends StatefulWidget {
  final String customerId;

  const CustomerMMEListPage({super.key, required this.customerId});

  @override
  State<CustomerMMEListPage> createState() => _CustomerMMEListPageState();
}

class _CustomerMMEListPageState extends State<CustomerMMEListPage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedStatusFilter = 'all'; // 'all', 'overdue', 'due_soon', 'valid'

  @override
  void initState() {
    super.initState();
    context.read<CustomerMMECubit>().loadMME(widget.customerId);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<CustomerMMEModel> _getFilteredList(
      List<CustomerMMEModel> originalList) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thirtyDaysLater = today.add(const Duration(days: 30));

    return originalList.where((mme) {
      // 1. Calibration Status Filter
      if (selectedStatusFilter == 'overdue') {
        if (!mme.nextCalibrationDate.isBefore(today)) {
          return false;
        }
      } else if (selectedStatusFilter == 'due_soon') {
        final isDueSoon = (mme.nextCalibrationDate.isAfter(today) ||
                mme.nextCalibrationDate.isAtSameMomentAs(today)) &&
            mme.nextCalibrationDate.isBefore(thirtyDaysLater);
        if (!isDueSoon) {
          return false;
        }
      } else if (selectedStatusFilter == 'valid') {
        if (mme.nextCalibrationDate.isBefore(today)) {
          return false;
        }
      }

      // 2. Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final device = mme.deviceName.toLowerCase();
        final serial = mme.serialNumber.toLowerCase();
        final idStr = mme.id.toLowerCase();

        final matches =
            device.contains(q) || serial.contains(q) || idStr.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
        ),
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            selectedStatusFilter = value;
          });
        }
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔍 SEARCH BAR
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search equipment by name, serial, ID...",
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.kPrimaryColor),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) {
              setState(() {
                searchQuery = val;
              });
            },
          ),

          /// 🏷️ STATUS CHIPS
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All", "all", AppColors.kPrimaryColor),
                const SizedBox(width: 8),
                _buildFilterChip("Overdue", "overdue", Colors.redAccent),
                const SizedBox(width: 8),
                _buildFilterChip("Due Soon", "due_soon", Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip("Valid", "valid", Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationStatusBadge(DateTime nextDueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thirtyDaysLater = today.add(const Duration(days: 30));

    if (nextDueDate.isBefore(today)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "OVERDUE",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    } else if (nextDueDate.isBefore(thirtyDaysLater)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "DUE SOON",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "VALID",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
        ),
        title: const Text(
          'Monitoring & Measuring Equipment',
          style: TextStyle(color: AppColors.whiteTextColor),
        ),
        backgroundColor: AppColors.kPrimaryColor,
        actions: [
          IconButton(
            tooltip: 'Upload MME Excel File',
            color: AppColors.whiteColor,
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              try {
                final cubit = context.read<CustomerMMECubit>();
                final excelList = await cubit.readMMEFromCsvWeb();

                if (excelList.isNotEmpty) {
                  if (context.mounted) {
                    _showExcelPreviewDialog(context, excelList);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Failed to upload Excel'),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Download MME Excel Format',
            color: AppColors.whiteColor,
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final _ = await context
                    .read<CustomerMMECubit>()
                    .downloadMMECsvTemplateWeb();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Failed to generate Excel'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.buttonDarkGreen,
        onPressed: () {
          context.push(
            AppRoutes.customerMMEForm,
            extra: {'customerId': widget.customerId},
          );
        },
        child: const Icon(Icons.add, color: AppColors.buttonYellow),
      ),
      body: BlocBuilder<CustomerMMECubit, CustomerMMEState>(
        builder: (context, state) {
          if (state is CustomerMMELoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CustomerMMELoaded) {
            final allMme = state.list;
            final filteredMme = _getFilteredList(allMme);

            return Column(
              children: [
                /// 🔍 SEARCH & FILTERS
                _buildSearchAndFilters(),

                /// 📋 MME LIST
                Expanded(
                  child: filteredMme.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                allMme.isEmpty
                                    ? 'No MME Found'
                                    : 'No matching equipment found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (searchQuery.isNotEmpty ||
                                  selectedStatusFilter != 'all') ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("CLEAR FILTERS"),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                      selectedStatusFilter = 'all';
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: filteredMme.length,
                          itemBuilder: (_, i) {
                            final mme = filteredMme[i];
                            final titleName = mme.deviceName.isNotEmpty
                                ? mme.deviceName[0].toUpperCase() +
                                    mme.deviceName.substring(1)
                                : 'Equipment';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _showMMEDetailsDialog(context, mme);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppColors.kPrimaryLightColor,
                                      child: Text(
                                        mme.id.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.kPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            titleName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        _buildCalibrationStatusBadge(
                                          mme.nextCalibrationDate,
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "SN: ${mme.serialNumber} • Next Due: ${DateFormat('dd MMM yyyy').format(mme.nextCalibrationDate)}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            context.push(
                                              AppRoutes.customerMMEForm,
                                              extra: {
                                                'customerId': widget.customerId,
                                                'mme': mme,
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            _showDeleteConfirmDialog(
                                              context,
                                              mme,
                                              widget.customerId,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          if (state is CustomerMMEError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _showMMEDetailsDialog(BuildContext context, CustomerMMEModel mme) {
    final screenWidth = MediaQuery.of(context).size.width;

    double dialogWidth;
    if (screenWidth < 600) {
      dialogWidth = screenWidth * 0.95; // mobile
    } else if (screenWidth < 1024) {
      dialogWidth = screenWidth * 0.7; // tablet
    } else {
      dialogWidth = 450; // web fixed width
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: dialogWidth,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Title
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.deepPurple.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mme.deviceName.isNotEmpty
                              ? mme.deviceName[0].toUpperCase() +
                                  mme.deviceName.substring(1)
                              : 'Equipment',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _infoRow(Icons.tag, 'ID', mme.id.toString()),
                  _infoRow(
                    Icons.confirmation_number,
                    'Serial',
                    mme.serialNumber,
                  ),
                  _infoRow(
                    Icons.event,
                    'Last Calibration',
                    DateFormat('dd MMM yyyy').format(mme.lastCalibrationDate),
                  ),
                  _infoRow(
                    Icons.schedule,
                    'Next Due',
                    DateFormat('dd MMM yyyy').format(mme.nextCalibrationDate),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonDarkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(color: AppColors.buttonYellow),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    CustomerMMEModel mme,
    String customerId,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete MME'),
          content: Text(
            'Are you sure you want to delete\n"${mme.deviceName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonDarkGreen),
              onPressed: () {
                if ((mme.docId ?? '').isNotEmpty) {
                  GoRouter.of(context).pop();
                  context.read<CustomerMMECubit>().deleteMME(
                        mme.docId!,
                        customerId,
                      );
                }
              },
              child: const Text(
                'DELETE',
                style: TextStyle(color: AppColors.buttonYellow),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExcelPreviewDialog(
    BuildContext context,
    List<CustomerMMEModel> list,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        final width = MediaQuery.of(context).size.width;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: width > 700 ? 650 : width * 0.95,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔷 Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.deepPurple.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'MME from Excel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${list.length}',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// 📋 List
                  Flexible(
                    child: list.isEmpty
                        ? const Center(
                            child: Text('No valid MME records found'),
                          )
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final mme = list[i];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.deepPurple
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mme.deviceName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'SN: ${mme.serialNumber}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔘 Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonDarkGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: list.isEmpty
                              ? null
                              : () {
                                  context
                                      .read<CustomerMMECubit>()
                                      .uploadExcelMME(widget.customerId, list);
                                  GoRouter.of(context).pop();
                                },
                          child: const Text(
                            'CONFIRM & UPLOAD',
                            style: TextStyle(color: AppColors.buttonYellow),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
