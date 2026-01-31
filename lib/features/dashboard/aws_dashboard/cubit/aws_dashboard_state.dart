import '../models/aws_resources_model.dart';

abstract class AwsDashboardState {}

class AwsDashboardInitial extends AwsDashboardState {}

class AwsDashboardLoading extends AwsDashboardState {}

class AwsDashboardLoaded extends AwsDashboardState {
  final AwsResourcesModel data;
  AwsDashboardLoaded(this.data);
}

class AwsDashboardError extends AwsDashboardState {
  final String message;
  AwsDashboardError(this.message);
}
