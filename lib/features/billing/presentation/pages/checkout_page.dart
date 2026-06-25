import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/data/hive_database.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/domain/entities/transaction_item.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _cashController = TextEditingController();
  double _cashReceived = 0;

  static final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  String _nextInvoiceNumber() {
    final counter =
        (HiveDatabase.settingsBox.get('invoice_counter') as int? ?? 0) + 1;
    HiveDatabase.settingsBox.put('invoice_counter', counter);
    return 'INV-${counter.toString().padLeft(4, '0')}';
  }

  void _onClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Transaksi?'),
        content: const Text(
            'Semua item di keranjang akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/');
            },
            child: const Text('Ya, Batalkan',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmCheckout(BuildContext context, BillingState billingState) {
    if (_paymentMethod == PaymentMethod.cash &&
        _cashReceived < billingState.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Uang diterima kurang dari total belanja'),
          backgroundColor: Colors.red));
      return;
    }

    final invoiceNumber = _nextInvoiceNumber();

    final transaction = Transaction(
      id: const Uuid().v4(),
      invoiceNumber: invoiceNumber,
      createdAt: DateTime.now(),
      items: billingState.cartItems
          .map((item) => TransactionItem(
                productId: item.product.id,
                productName: item.product.name,
                price: item.product.price,
                quantity: item.quantity,
                total: item.total,
              ))
          .toList(),
      totalAmount: billingState.totalAmount,
      paymentMethod: _paymentMethod,
      cashReceived: _cashReceived,
    );

    // Deduct stock for each item, clamped to 0
    for (final cartItem in billingState.cartItems) {
      final newStock = (cartItem.product.stock - cartItem.quantity)
          .clamp(0, double.maxFinite.toInt());
      final updatedProduct = Product(
        id: cartItem.product.id,
        name: cartItem.product.name,
        barcode: cartItem.product.barcode,
        price: cartItem.product.price,
        stock: newStock,
      );
      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
    }

    context.read<TransactionBloc>().add(SaveTransactionEvent(transaction));
    context.read<BillingBloc>().add(ClearCartEvent());
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onClearCart(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => _onClearCart(context),
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listener: (context, state) {
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Struk berhasil dicetak'),
                  backgroundColor: Colors.green));
            }
          },
          builder: (context, billingState) {
            return BlocBuilder<ShopBloc, ShopState>(
              builder: (context, shopState) {
                String upiId = '';
                String shopName = 'Shop';
                if (shopState is ShopLoaded) {
                  upiId = shopState.shop.upiId;
                  shopName = shopState.shop.name;
                }

                final double change = _paymentMethod == PaymentMethod.cash
                    ? (_cashReceived - billingState.totalAmount)
                        .clamp(0.0, double.infinity)
                    : 0.0;

                return Column(
                  children: [
                    // Cart items table
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  border: const TableBorder(
                                    horizontalInside:
                                        BorderSide(color: borderColor),
                                    bottom: BorderSide(color: borderColor),
                                  ),
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        border: Border(
                                            bottom: BorderSide(
                                                color: borderColor)),
                                      ),
                                      children: [
                                        _buildHeaderCell(
                                            'Produk', TextAlign.left),
                                        _buildHeaderCell(
                                            'Harga', TextAlign.right),
                                        _buildHeaderCell(
                                            'Total', TextAlign.right),
                                      ],
                                    ),
                                    ...billingState.cartItems.map((item) {
                                      return TableRow(
                                        children: [
                                          _buildDataCell(
                                              '${item.quantity} x ${item.product.name}',
                                              TextAlign.left),
                                          _buildDataCell(
                                              _fmt.format(item.product.price),
                                              TextAlign.right,
                                              isSubtitle: true),
                                          _buildDataCell(
                                              _fmt.format(item.total),
                                              TextAlign.right,
                                              isBold: true),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 200),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Payment method toggle
                                Row(
                                  children: [
                                    Expanded(
                                      child: _PaymentMethodButton(
                                        label: 'Tunai',
                                        icon: Icons.payments_outlined,
                                        selected: _paymentMethod ==
                                            PaymentMethod.cash,
                                        onTap: () => setState(() {
                                          _paymentMethod = PaymentMethod.cash;
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _PaymentMethodButton(
                                        label: 'QRIS',
                                        icon: Icons.qr_code_outlined,
                                        selected: _paymentMethod ==
                                            PaymentMethod.qris,
                                        onTap: () => setState(() {
                                          _paymentMethod = PaymentMethod.qris;
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Cash input or QRIS
                                if (_paymentMethod == PaymentMethod.cash) ...[
                                  TextFormField(
                                    controller: _cashController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Uang Diterima',
                                      prefixText: 'Rp ',
                                      prefixStyle: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    onChanged: (v) => setState(() {
                                      _cashReceived =
                                          double.tryParse(v) ?? 0;
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Kembalian',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14)),
                                      Text(
                                        _fmt.format(change),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: change >= 0
                                              ? Colors.green[700]
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (upiId.isNotEmpty) ...[
                                  Center(
                                    child: Column(
                                      children: [
                                        const Text('Scan QRIS untuk Bayar',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: 160,
                                          height: 160,
                                          child: PrettyQrView.data(
                                            data:
                                                'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(0)}&cu=IDR',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 8),
                                // Grand Total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('GRAND TOTAL',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[400],
                                          letterSpacing: 1.2,
                                        )),
                                    Text(
                                      _fmt.format(billingState.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Print button
                          PrimaryButton(
                            onPressed: () {
                              if (shopState is ShopLoaded) {
                                context.read<BillingBloc>().add(
                                    PrintReceiptEvent(
                                        shopName: shopState.shop.name,
                                        address1: shopState.shop.addressLine1,
                                        address2: shopState.shop.addressLine2,
                                        phone: shopState.shop.phoneNumber,
                                        footer: shopState.shop.footerText,
                                        paymentMethod:
                                            _paymentMethod == PaymentMethod.cash
                                                ? 'Tunai'
                                                : 'QRIS',
                                        cashReceived: _cashReceived,
                                        change: change));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Data toko belum diisi'),
                                        backgroundColor: Colors.red));
                              }
                            },
                            label: 'Cetak Struk',
                            icon: Icons.print,
                            isLoading: billingState.isPrinting,
                          ),

                          // Confirm button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: billingState.cartItems.isEmpty
                                    ? null
                                    : () => _confirmCheckout(
                                        context, billingState),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Konfirmasi Pembayaran'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : Colors.black87,
        ),
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? color : Colors.grey[600],
                )),
          ],
        ),
      ),
    );
  }
}
