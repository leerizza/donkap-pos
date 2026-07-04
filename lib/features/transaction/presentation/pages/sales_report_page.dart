import 'package:fl_chart/fl_chart.dart';
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

class _SalesReportPageState extends State<SalesReportPage>
    with SingleTickerProviderStateMixin {
  _DateFilter _filter = _DateFilter.today;
  bool _exporting = false;
  final _exportService = ExportService();
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
    context.read<TransactionBloc>().add(const LoadTransactionsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              const SizedBox(height: 8),

              TabBar(
                controller: _tabController,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13),
                tabs: const [
                  Tab(text: 'Transaksi'),
                  Tab(text: 'Analitik'),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0 — Transaksi
                    filtered.isEmpty
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
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _TransactionCard(
                                transaction: filtered[index],
                                formatter: _rupiahFormatter,
                                onDelete: () => _confirmDelete(
                                    context, filtered[index].id),
                              );
                            },
                          ),

                    // Tab 1 — Analitik
                    _AnalyticsView(
                      filtered: filtered,
                      filter: _filter,
                      formatter: _rupiahFormatter,
                    ),
                  ],
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
                    color: switch (transaction.paymentMethod) {
                      PaymentMethod.cash => Colors.green.withValues(alpha: 0.1),
                      PaymentMethod.transfer => Colors.orange.withValues(alpha: 0.1),
                      PaymentMethod.qris => Colors.blue.withValues(alpha: 0.1),
                    },
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    switch (transaction.paymentMethod) {
                      PaymentMethod.cash => 'Tunai',
                      PaymentMethod.transfer => 'Transfer',
                      PaymentMethod.qris => 'QRIS',
                    },
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: switch (transaction.paymentMethod) {
                        PaymentMethod.cash => Colors.green[700],
                        PaymentMethod.transfer => Colors.orange[700],
                        PaymentMethod.qris => Colors.blue[700],
                      },
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

// ─── Analytics Tab ────────────────────────────────────────────────────────────

class _AnalyticsView extends StatelessWidget {
  final List<Transaction> filtered;
  final _DateFilter filter;
  final NumberFormat formatter;

  const _AnalyticsView({
    required this.filtered,
    required this.filter,
    required this.formatter,
  });

  static const _barColor = Color(0xFF6366F1);
  static const _emptyBarColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada data', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final chartInfo = _buildChartInfo();
    final topProducts = _buildTopProducts();
    final maxY = chartInfo.groups
        .map((g) => g.barRods.first.toY)
        .fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── Bar chart ──────────────────────────────
        Text(chartInfo.title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY == 0 ? 1 : maxY * 1.25,
              barGroups: chartInfo.groups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.grey[200]!, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    getTitlesWidget: (v, _) => Text(
                      _compactRp(v),
                      style: const TextStyle(
                          fontSize: 9, color: Colors.grey),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final label = chartInfo.xLabel(v.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
                    formatter.format(rod.toY),
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Top products ───────────────────────────
        const Text('Produk Terlaris',
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('berdasarkan qty terjual',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),
        if (topProducts.isEmpty)
          const Text('Tidak ada data produk.',
              style: TextStyle(color: Colors.grey))
        else
          ...topProducts.take(7).toList().asMap().entries.map((e) {
            final rank = e.key + 1;
            final name = e.value.key;
            final qty = e.value.value;
            final revenue = _productRevenue(name);
            final maxQty = topProducts.first.value;
            return _TopProductRow(
              rank: rank,
              name: name,
              qty: qty,
              revenue: revenue,
              maxQty: maxQty,
              formatter: formatter,
            );
          }),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────

  _ChartInfo _buildChartInfo() {
    final now = DateTime.now();

    switch (filter) {
      case _DateFilter.today:
        final Map<int, double> hourly = {};
        for (final tx in filtered) {
          final h = tx.createdAt.hour;
          hourly[h] = (hourly[h] ?? 0) + tx.totalAmount;
        }
        final hours = hourly.keys.toList()..sort();
        return _ChartInfo(
          title: 'Penjualan per Jam',
          groups: hours
              .asMap()
              .entries
              .map((e) => _rod(e.key, hourly[e.value]!))
              .toList(),
          xLabel: (i) => i < hours.length ? '${hours[i]}h' : '',
        );

      case _DateFilter.week:
        final Map<int, double> daily = {};
        for (final tx in filtered) {
          final diff = now.difference(tx.createdAt).inDays;
          if (diff >= 0 && diff < 7) {
            final idx = 6 - diff;
            daily[idx] = (daily[idx] ?? 0) + tx.totalAmount;
          }
        }
        final dayNames = List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          return DateFormat('E', 'id_ID').format(d);
        });
        return _ChartInfo(
          title: 'Penjualan 7 Hari Terakhir',
          groups: List.generate(7, (i) => _rod(i, daily[i] ?? 0)),
          xLabel: (i) => i < dayNames.length ? dayNames[i] : '',
        );

      case _DateFilter.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final Map<int, double> daily = {};
        for (final tx in filtered) {
          final d = tx.createdAt.day;
          daily[d] = (daily[d] ?? 0) + tx.totalAmount;
        }
        return _ChartInfo(
          title: 'Penjualan Bulan Ini',
          groups: List.generate(
              daysInMonth, (i) => _rod(i, daily[i + 1] ?? 0)),
          xLabel: (i) => (i + 1) % 5 == 1 ? '${i + 1}' : '',
        );

      case _DateFilter.all:
        final Map<String, double> monthly = {};
        for (final tx in filtered) {
          final key =
              '${tx.createdAt.year}-${tx.createdAt.month.toString().padLeft(2, '0')}';
          monthly[key] = (monthly[key] ?? 0) + tx.totalAmount;
        }
        final keys = monthly.keys.toList()..sort();
        return _ChartInfo(
          title: 'Penjualan per Bulan',
          groups: keys
              .asMap()
              .entries
              .map((e) => _rod(e.key, monthly[e.value]!))
              .toList(),
          xLabel: (i) {
            if (i >= keys.length) return '';
            final parts = keys[i].split('-');
            return DateFormat('MMM', 'id_ID')
                .format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
          },
        );
    }
  }

  List<MapEntry<String, int>> _buildTopProducts() {
    final Map<String, int> qty = {};
    for (final tx in filtered) {
      for (final item in tx.items) {
        qty[item.productName] = (qty[item.productName] ?? 0) + item.quantity;
      }
    }
    return qty.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  double _productRevenue(String name) {
    double total = 0;
    for (final tx in filtered) {
      for (final item in tx.items) {
        if (item.productName == name) total += item.total;
      }
    }
    return total;
  }

  BarChartGroupData _rod(int x, double y) => BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y,
            color: y > 0 ? _barColor : _emptyBarColor,
            width: 12,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );

  String _compactRp(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }
}

class _ChartInfo {
  final String title;
  final List<BarChartGroupData> groups;
  final String Function(int) xLabel;

  const _ChartInfo({
    required this.title,
    required this.groups,
    required this.xLabel,
  });
}

class _TopProductRow extends StatelessWidget {
  final int rank;
  final String name;
  final int qty;
  final double revenue;
  final int maxQty;
  final NumberFormat formatter;

  const _TopProductRow({
    required this.rank,
    required this.name,
    required this.qty,
    required this.revenue,
    required this.maxQty,
    required this.formatter,
  });

  static const _rankColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  @override
  Widget build(BuildContext context) {
    final barFraction = maxQty > 0 ? qty / maxQty : 0.0;
    final rankColor = rank <= 3 ? _rankColors[rank - 1] : Colors.grey[300]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$rank',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rankColor == Colors.grey[300]
                        ? Colors.grey
                        : rankColor.withValues(alpha: 0.9))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis)),
                    Text('$qty pcs',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barFraction,
                    minHeight: 6,
                    backgroundColor: Colors.grey[100],
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(formatter.format(revenue),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
