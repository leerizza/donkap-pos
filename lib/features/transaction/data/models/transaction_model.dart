import 'package:hive/hive.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_item_model.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
class TransactionModel extends Transaction {
  @override
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int createdAtMs;

  @HiveField(2)
  final List<TransactionItemModel> itemModels;

  @override
  @HiveField(3)
  final double totalAmount;

  TransactionModel({
    required this.id,
    required this.createdAtMs,
    required this.itemModels,
    required this.totalAmount,
  }) : super(
          id: id,
          createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
          items: itemModels,
          totalAmount: totalAmount,
        );

  factory TransactionModel.fromEntity(Transaction tx) {
    return TransactionModel(
      id: tx.id,
      createdAtMs: tx.createdAt.millisecondsSinceEpoch,
      itemModels: tx.items.map(TransactionItemModel.fromEntity).toList(),
      totalAmount: tx.totalAmount,
    );
  }
}
