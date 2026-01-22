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
