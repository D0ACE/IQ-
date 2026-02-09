import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_state.dart';
import 'package:iq_plus/features/customer_mme/models/mme_model_req.dart';
import 'package:iq_plus/features/customer_mme/pages/customer_mme_form_page.dart';
import 'package:iq_plus/features/customer_mme/repository/customer_mme_repository.dart';

class CustomerMMEListPage extends StatefulWidget {
  final String customerId;

  const CustomerMMEListPage({super.key, required this.customerId});

  @override
  State<CustomerMMEListPage> createState() => _CustomerMMEListPageState();
}

class _CustomerMMEListPageState extends State<CustomerMMEListPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerMMECubit>().loadMME(widget.customerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(onTap:()=> Navigator.pop(context),child: Icon(Icons.arrow_back,color: AppColors.whiteColor,)),
        title: const Text('Monitoring and Measuring Equipment',style: TextStyle(color: AppColors.whiteTextColor),),
        backgroundColor: AppColors.kPrimaryColor,
        actions: [
          IconButton(
            tooltip: 'Upload MME Excel File',
            color: AppColors.whiteColor,
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              try{
                final cubit = context.read<CustomerMMECubit>();
                final excelList = await cubit.readMMEFromCsvWeb();

                if (excelList.isNotEmpty){
                  _showExcelPreviewDialog(context, excelList);
                }
              }catch(e){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Failed to upload Excel'),
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Download MME Excel Format',
            color: AppColors.whiteColor,
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final file = await context
                    .read<CustomerMMECubit>()
                    .downloadMMECsvTemplateWeb();

                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('Excel downloaded to:\n${file.path}'),
                //   ),
                // );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Failed to generate Excel'),
                  ),
                );
              }
            },
          ),

        ],

      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kPrimaryColor,
        onPressed: () {
          context.push(
            AppRoutes.customerMMEForm, // route path for edit page
            extra: {
              'customerId': widget.customerId,
            },
          );
        },
        child: const Icon(Icons.add,color: AppColors.whiteColor,),
      ),
      body: BlocBuilder<CustomerMMECubit, CustomerMMEState>(
        builder: (context, state) {
          if (state is CustomerMMELoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CustomerMMELoaded) {
            if (state.list.isEmpty) {
              return const Center(child: Text('No MME Found'));
            }

            return ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: state.list.length,
              itemBuilder: (_, i) {
                final mme = state.list[i];
                return Material(
                  color: Colors.transparent, // or any background color
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: (){
                      _showMMEDetailsDialog(context, mme);
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading:
                          CircleAvatar(child: Text(mme.id.toUpperCase(),)),
                          title: Text(mme.deviceName[0].toUpperCase() + mme.deviceName.substring(1)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit, color: Colors.blue),
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
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmDialog(context, mme, widget.customerId);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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

  void _showMMEDetailsDialog(
      BuildContext context,
      CustomerMMEModel mme,
      ) {
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
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mme.deviceName[0].toUpperCase() + mme.deviceName.substring(1),
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
                  _infoRow(Icons.confirmation_number, 'Serial', mme.serialNumber),
                  _infoRow(
                    Icons.event,
                    'Last Calibration',
                    DateFormat('dd MMM yyyy')
                        .format(mme.lastCalibrationDate),
                  ),
                  _infoRow(
                    Icons.schedule,
                    'Next Due',
                    DateFormat('dd MMM yyyy')
                        .format(mme.nextCalibrationDate),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close',style: TextStyle(color:AppColors.whiteTextColor),),
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
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                if((mme.docId??'').isNotEmpty)
                {
                  GoRouter.of(context).pop();
                  context
                      .read<CustomerMMECubit>()
                      .deleteMME(mme.docId!, customerId);
                }
              },
              child: const Text('Delete',style: TextStyle(color: AppColors.whiteTextColor),),
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
            width: width > 700 ? 650 : width * 0.95, // ✅ responsive width
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
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        child: const Icon(
                          Icons.upload_file,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'MME from Excel',
                          style: const TextStyle(
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
                          color: Colors.deepPurple.withOpacity(0.1),
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
                      separatorBuilder: (_, __) =>
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
                                backgroundColor:
                                Colors.deepPurple.withOpacity(0.15),
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
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: list.isEmpty
                              ? null
                              : () {
                            context
                                .read<CustomerMMECubit>()
                                .uploadExcelMME(
                              widget.customerId,
                              list,
                            );
                            GoRouter.of(context).pop();
                          },
                          child: const Text('CONFIRM & UPLOAD',style: TextStyle(color: AppColors.whiteTextColor),),
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


