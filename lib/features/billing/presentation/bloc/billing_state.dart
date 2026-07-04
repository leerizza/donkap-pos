part of 'billing_bloc.dart';

enum DiscountType { nominal, percent }

class BillingState extends Equatable {
  final List<CartItem> cartItems;
  final String? error;
  final bool isPrinting;
  final bool printSuccess;
  final double discountInput;
  final DiscountType discountType;

  const BillingState({
    this.cartItems = const [],
    this.error,
    this.isPrinting = false,
    this.printSuccess = false,
    this.discountInput = 0,
    this.discountType = DiscountType.nominal,
  });

  double get subtotal => cartItems.fold(0, (sum, item) => sum + item.total);

  double get discountAmount {
    if (discountType == DiscountType.percent) {
      return (subtotal * discountInput / 100).clamp(0, subtotal);
    }
    return discountInput.clamp(0, subtotal);
  }

  double get totalAmount => (subtotal - discountAmount).clamp(0, double.infinity);

  BillingState copyWith({
    List<CartItem>? cartItems,
    String? error,
    bool clearError = false,
    bool? isPrinting,
    bool? printSuccess,
    double? discountInput,
    DiscountType? discountType,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      error: clearError ? null : (error ?? this.error),
      isPrinting: isPrinting ?? this.isPrinting,
      printSuccess: printSuccess ?? this.printSuccess,
      discountInput: discountInput ?? this.discountInput,
      discountType: discountType ?? this.discountType,
    );
  }

  @override
  List<Object?> get props => [cartItems, error, isPrinting, printSuccess, discountInput, discountType];
}
