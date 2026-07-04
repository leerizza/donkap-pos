part of 'stock_adjustment_bloc.dart';

abstract class StockAdjustmentEvent extends Equatable {
  const StockAdjustmentEvent();

  @override
  List<Object> get props => [];
}

class LoadStockAdjustments extends StockAdjustmentEvent {}

class SaveStockAdjustment extends StockAdjustmentEvent {
  final StockAdjustment adjustment;
  const SaveStockAdjustment(this.adjustment);
  @override
  List<Object> get props => [adjustment];
}
