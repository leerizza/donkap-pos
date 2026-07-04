import 'package:equatable/equatable.dart';

enum StockAdjustmentReason { damaged, lost, correction, other }

class StockAdjustment extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int previousStock;
  final int newStock;
  final StockAdjustmentReason reason;
  final String note;
  final DateTime createdAt;

  int get delta => newStock - previousStock;

  const StockAdjustment({
    required this.id,
    required this.productId,
    required this.productName,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    this.note = '',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        previousStock,
        newStock,
        reason,
        note,
        createdAt,
      ];
}
