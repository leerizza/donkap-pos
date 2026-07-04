part of 'stock_adjustment_bloc.dart';

enum StockAdjustmentStatus { initial, loading, loaded, error, success }

class StockAdjustmentState extends Equatable {
  final StockAdjustmentStatus status;
  final List<StockAdjustment> adjustments;
  final String? message;

  const StockAdjustmentState({
    this.status = StockAdjustmentStatus.initial,
    this.adjustments = const [],
    this.message,
  });

  StockAdjustmentState copyWith({
    StockAdjustmentStatus? status,
    List<StockAdjustment>? adjustments,
    String? message,
  }) {
    return StockAdjustmentState(
      status: status ?? this.status,
      adjustments: adjustments ?? this.adjustments,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, adjustments, message];
}
