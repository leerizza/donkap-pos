import 'package:equatable/equatable.dart';
import 'transaction_item.dart';

class Transaction extends Equatable {
  final String id;
  final DateTime createdAt;
  final List<TransactionItem> items;
  final double totalAmount;

  const Transaction({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.totalAmount,
  });

  @override
  List<Object> get props => [id, createdAt, items, totalAmount];
}
