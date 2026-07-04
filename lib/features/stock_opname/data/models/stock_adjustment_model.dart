import 'package:hive/hive.dart';
import '../../domain/entities/stock_adjustment.dart';

part 'stock_adjustment_model.g.dart';

@HiveType(typeId: 4)
class StockAdjustmentModel extends StockAdjustment {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String productId;
  @override
  @HiveField(2)
  final String productName;
  @override
  @HiveField(3)
  final int previousStock;
  @override
  @HiveField(4)
  final int newStock;
  @HiveField(5)
  final String reasonRaw;
  @override
  @HiveField(6)
  final String note;
  @HiveField(7)
  final int createdAtMs;

  StockAdjustmentModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.previousStock,
    required this.newStock,
    required this.reasonRaw,
    this.note = '',
    required this.createdAtMs,
  }) : super(
          id: id,
          productId: productId,
          productName: productName,
          previousStock: previousStock,
          newStock: newStock,
          reason: StockAdjustmentReason.values.firstWhere(
            (r) => r.name == reasonRaw,
            orElse: () => StockAdjustmentReason.other,
          ),
          note: note,
          createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        );

  factory StockAdjustmentModel.fromEntity(StockAdjustment adjustment) {
    return StockAdjustmentModel(
      id: adjustment.id,
      productId: adjustment.productId,
      productName: adjustment.productName,
      previousStock: adjustment.previousStock,
      newStock: adjustment.newStock,
      reasonRaw: adjustment.reason.name,
      note: adjustment.note,
      createdAtMs: adjustment.createdAt.millisecondsSinceEpoch,
    );
  }
}
