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

  @HiveField(4)
  final String? invoiceNumberRaw;

  @HiveField(5)
  final String? paymentMethodRaw;

  @HiveField(6)
  final double? cashReceivedRaw;

  @HiveField(7)
  final double? discountAmountRaw;

  TransactionModel({
    required this.id,
    required this.createdAtMs,
    required this.itemModels,
    required this.totalAmount,
    this.invoiceNumberRaw,
    this.paymentMethodRaw,
    this.cashReceivedRaw,
    this.discountAmountRaw,
  }) : super(
          id: id,
          invoiceNumber: invoiceNumberRaw ?? '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
          items: itemModels,
          totalAmount: totalAmount,
          paymentMethod: paymentMethodRaw == 'cash'
              ? PaymentMethod.cash
              : paymentMethodRaw == 'transfer'
                  ? PaymentMethod.transfer
                  : PaymentMethod.qris,
          cashReceived: cashReceivedRaw ?? 0,
          discountAmount: discountAmountRaw ?? 0,
        );

  factory TransactionModel.fromEntity(Transaction tx) {
    return TransactionModel(
      id: tx.id,
      createdAtMs: tx.createdAt.millisecondsSinceEpoch,
      itemModels: tx.items.map(TransactionItemModel.fromEntity).toList(),
      totalAmount: tx.totalAmount,
      invoiceNumberRaw: tx.invoiceNumber,
      paymentMethodRaw: tx.paymentMethod.name,
      cashReceivedRaw: tx.cashReceived,
      discountAmountRaw: tx.discountAmount,
    );
  }
}
