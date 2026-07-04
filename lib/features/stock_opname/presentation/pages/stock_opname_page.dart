import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../domain/entities/stock_adjustment.dart';
import '../bloc/stock_adjustment_bloc.dart';

String reasonLabel(StockAdjustmentReason reason) {
  switch (reason) {
    case StockAdjustmentReason.damaged:
      return 'Rusak';
    case StockAdjustmentReason.lost:
      return 'Hilang';
    case StockAdjustmentReason.correction:
      return 'Koreksi';
    case StockAdjustmentReason.other:
      return 'Lainnya';
  }
}

class StockOpnamePage extends StatefulWidget {
  const StockOpnamePage({super.key});

  @override
  State<StockOpnamePage> createState() => _StockOpnamePageState();
}

class _StockOpnamePageState extends State<StockOpnamePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<StockAdjustmentBloc>().add(LoadStockAdjustments());
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAdjustDialog(Product product) {
    final controller = TextEditingController(text: product.stock.toString());
    final noteController = TextEditingController();
    StockAdjustmentReason reason = StockAdjustmentReason.correction;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Sesuaikan Stok: ${product.name}'),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stok sistem saat ini: ${product.stock}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Stok fisik hasil hitung',
                  suffixText: 'pcs',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StockAdjustmentReason>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Alasan'),
                items: StockAdjustmentReason.values
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(reasonLabel(r))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => reason = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
                maxLines: 2,
              ),
            ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final newStock =
                    int.tryParse(controller.text) ?? product.stock;
                if (newStock == product.stock) {
                  Navigator.pop(dialogCtx);
                  return;
                }
                final adjustment = StockAdjustment(
                  id: const Uuid().v4(),
                  productId: product.id,
                  productName: product.name,
                  previousStock: product.stock,
                  newStock: newStock.clamp(0, 1 << 31),
                  reason: reason,
                  note: noteController.text.trim(),
                  createdAt: DateTime.now(),
                );
                context
                    .read<StockAdjustmentBloc>()
                    .add(SaveStockAdjustment(adjustment));
                context.read<ProductBloc>().add(UpdateProduct(Product(
                      id: product.id,
                      name: product.name,
                      barcode: product.barcode,
                      price: product.price,
                      stock: adjustment.newStock,
                      category: product.category,
                    )));
                Navigator.pop(dialogCtx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Stock Opname',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sesuaikan'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdjustTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildAdjustTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk',
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              final products = state.products
                  .where((p) => p.name.toLowerCase().contains(_searchQuery))
                  .toList();
              if (products.isEmpty) {
                return const Center(child: Text('Tidak ada produk.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('Stok sistem: ${product.stock}'),
                    trailing: OutlinedButton(
                      onPressed: () => _openAdjustDialog(product),
                      child: const Text('Sesuaikan'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<StockAdjustmentBloc, StockAdjustmentState>(
      builder: (context, state) {
        if (state.status == StockAdjustmentStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.adjustments.isEmpty) {
          return const Center(child: Text('Belum ada riwayat penyesuaian.'));
        }
        final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.adjustments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final adj = state.adjustments[index];
            final isIncrease = adj.delta > 0;
            final deltaColor = adj.delta == 0
                ? Colors.grey
                : (isIncrease ? Colors.green : Colors.red);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(adj.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${reasonLabel(adj.reason)} · ${dateFmt.format(adj.createdAt)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (adj.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(adj.note,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncrease ? '+' : ''}${adj.delta}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: deltaColor),
                      ),
                      Text('${adj.previousStock} → ${adj.newStock}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
