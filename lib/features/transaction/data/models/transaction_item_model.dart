import 'package:hive/hive.dart';
import '../../domain/entities/transaction_item.dart';

part 'transaction_item_model.g.dart';

@HiveType(typeId: 2)
class TransactionItemModel extends TransactionItem {
  @override
  @HiveField(0)
  final String productId;
  @override
  @HiveField(1)
  final String productName;
  @override
  @HiveField(2)
  final double price;
  @override
  @HiveField(3)
  final int quantity;
  @override
  @HiveField(4)
  final double total;

  const TransactionItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  }) : super(
          productId: productId,
          productName: productName,
          price: price,
          quantity: quantity,
          total: total,
        );

  factory TransactionItemModel.fromEntity(TransactionItem item) {
    return TransactionItemModel(
      productId: item.productId,
      productName: item.productName,
      price: item.price,
      quantity: item.quantity,
      total: item.total,
    );
  }
}
