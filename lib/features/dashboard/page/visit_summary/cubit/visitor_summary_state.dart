import 'package:iq_plus/features/dashboard/page/visit_summary/model/visitor_summary_model.dart';

abstract class VisitorSummaryState {}

class VisitorSummaryInitial extends VisitorSummaryState {}

class VisitorSummaryLoading extends VisitorSummaryState {}

class VisitorSummarySuccess extends VisitorSummaryState {
  final String message;

  VisitorSummarySuccess(this.message);
}

class VisitorSummaryError extends VisitorSummaryState {
  final String error;

  VisitorSummaryError(this.error);
}


class VisitorSummaryLoaded extends VisitorSummaryState {
  final List<VisitorSummaryModel> list;
  VisitorSummaryLoaded(this.list);
}