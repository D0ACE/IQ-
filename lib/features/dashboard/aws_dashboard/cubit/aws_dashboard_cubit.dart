import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/aws_api_service.dart';
import 'aws_dashboard_state.dart';

class AwsDashboardCubit extends Cubit<AwsDashboardState> {
  AwsDashboardCubit() : super(AwsDashboardInitial());

  final _service = AwsApiService();

  Future<void> loadAwsResources() async {
    emit(AwsDashboardLoading());

    try {
      final data = await _service.fetchAwsResources();
      emit(AwsDashboardLoaded(data));
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      emit(AwsDashboardError(e.toString()));
    }
  }
}
