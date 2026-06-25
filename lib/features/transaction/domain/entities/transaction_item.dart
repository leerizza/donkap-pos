import 'package:equatable/equatable.dart';

class TransactionItem extends Equatable {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;

  const TransactionItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  @override
  List<Object> get props => [productId, productName, price, quantity, total];
}
