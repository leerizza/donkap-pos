import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/export_service.dart';
import '../bloc/transaction_bloc.dart';
import '../../domain/entities/transaction.dart';

enum _DateFilter { today, week, month, all }

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  _DateFilter _filter = _DateFilter.today;
  bool _exporting = false;
  final _exportService = ExportService();

  static const _filterLabels = {
    _DateFilter.today: 'Hari Ini',
    _DateFilter.week: 'Minggu Ini',
    _DateFilter.month: 'Bulan Ini',
    _DateFilter.all: 'Semua',
  };

  static final _rupiahFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const LoadTransactionsEvent());
  }

  Future<void> _showExportSheet() async {
    final state = context.read<TransactionBloc>().state;
    final all =
        state is TransactionLoaded ? state.transactions : <Transaction>[];
    final filtered = _applyFilter(all);

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diekspor')));
      return;
    }
    final periodLabel = _filterLabels[_filter]!;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Ekspor Laporan',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined,
                  color: Color(0xFF1D6F42)),
              title: const Text('Excel (.xlsx)'),
              subtitle: Text('${filtered.length} transaksi'),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _exporting = true);
                await _exportService.exportExcel(filtered, periodLabel);
                if (mounted) setState(() => _exporting = false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: Color(0xFFE53935)),
              title: const Text('PDF'),
              subtitle: Text('${filtered.length} transaksi'),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _exporting = true);
                await _exportService.exportPdf(filtered, periodLabel);
                if (mounted) setState(() => _exporting = false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Transaction> _applyFilter(List<Transaction> all) {
    final now = DateTime.now();
    return switch (_filter) {
      _DateFilter.today => all.where((t) {
          return t.createdAt.year == now.year &&
              t.createdAt.month == now.month &&
              t.createdAt.day == now.day;
        }).toList(),
      _DateFilter.week => all.where((t) {
          final diff = now.difference(t.createdAt).inDays;
          return diff >= 0 && diff < 7;
        }).toList(),
      _DateFilter.month => all.where((t) {
          return t.createdAt.year == now.year &&
              t.createdAt.month == now.month;
        }).toList(),
      _DateFilter.all => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: 'Ekspor',
              onPressed: _showExportSheet,
            ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionError) {
            return Center(child: Text(state.message));
          }

          final List<Transaction> all =
              state is TransactionLoaded ? state.transactions : const [];
          final filtered = _applyFilter(all);

          final totalRevenue =
              filtered.fold<double>(0, (sum, t) => sum + t.totalAmount);
          final totalItems = filtered.fold<int>(
              0,
              (sum, t) =>
                  sum + t.items.fold<int>(0, (s, i) => s + i.quantity));

          return Column(
            children: [
              // Filter chips
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: _DateFilter.values.map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_filterLabels[f]!,
                            style: const TextStyle(fontSize: 12)),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Summary cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Pendapatan',
                        value: _rupiahFormatter.format(totalRevenue),
                        icon: Icons.payments_outlined,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Transaksi',
                        value: '${filtered.length}',
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Item Terjual',
                        value: '$totalItems',
                        icon: Icons.shopping_bag_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transaction list
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Belum ada transaksi',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _TransactionCard(
                            transaction: filtered[index],
                            formatter: _rupiahFormatter,
                            onDelete: () =>
                                _confirmDelete(context, filtered[index].id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext outerContext, String id) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              outerContext
                  .read<TransactionBloc>()
                  .add(DeleteTransactionEvent(id));
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat formatter;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.formatter,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt);
    final totalItems =
        transaction.items.fold<int>(0, (s, i) => s + i.quantity);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_outlined,
              color: Color(0xFF6366F1), size: 20),
        ),
        title: Text(
          formatter.format(transaction.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.invoiceNumber.isNotEmpty)
              Text(transaction.invoiceNumber,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontFamily: 'monospace')),
            Text(dateStr,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$totalItems item',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.paymentMethod == PaymentMethod.cash
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.paymentMethod == PaymentMethod.cash
                        ? 'Tunai'
                        : 'QRIS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: transaction.paymentMethod == PaymentMethod.cash
                          ? Colors.green[700]
                          : Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
        children: transaction.items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.productName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  formatter.format(item.total),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
