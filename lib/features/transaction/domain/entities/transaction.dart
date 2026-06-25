import 'package:equatable/equatable.dart';
import 'transaction_item.dart';

enum PaymentMethod { cash, qris }

class Transaction extends Equatable {
  final String id;
  final String invoiceNumber;
  final DateTime createdAt;
  final List<TransactionItem> items;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final double cashReceived;

  double get change =>
      paymentMethod == PaymentMethod.cash ? cashReceived - totalAmount : 0;

  const Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.createdAt,
    required this.items,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.qris,
    this.cashReceived = 0,
  });

  @override
  List<Object> get props =>
      [id, invoiceNumber, createdAt, items, totalAmount, paymentMethod, cashReceived];
}
