import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/hive_database.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/transaction/data/models/transaction_item_model.dart';
import '../../features/transaction/data/models/transaction_model.dart';

class BackupService {
  static const int _version = 1;
  static const String _shopKey = 'shop_details';

  Future<void> exportBackup() async {
    final json = const JsonEncoder.withIndent('  ').convert(_collectData());
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/donkap_backup_$dateStr.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Donkap POS Backup $dateStr',
    );
  }

  /// Returns 'ok' on success, or an error message string.
  Future<String> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return 'batal';

    try {
      final content = await File(result.files.single.path!).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (data['version'] != _version) return 'Format backup tidak dikenal';
      await _restoreData(data);
      return 'ok';
    } catch (_) {
      return 'File backup rusak atau tidak valid';
    }
  }

  Map<String, dynamic> _collectData() {
    final products = HiveDatabase.productBox.values
        .map((p) => {
              'id': p.id,
              'name': p.name,
              'barcode': p.barcode,
              'price': p.price,
              'stock': p.stock,
            })
        .toList();

    final shopEntry = HiveDatabase.shopBox.get(_shopKey);
    final shop = shopEntry == null
        ? null
        : {
            'name': shopEntry.name,
            'addressLine1': shopEntry.addressLine1,
            'addressLine2': shopEntry.addressLine2,
            'phoneNumber': shopEntry.phoneNumber,
            'upiId': shopEntry.upiId,
            'footerText': shopEntry.footerText,
          };

    final transactions = HiveDatabase.transactionBox.values
        .map((tx) => {
              'id': tx.id,
              'createdAtMs': tx.createdAtMs,
              'totalAmount': tx.totalAmount,
              'invoiceNumber': tx.invoiceNumberRaw,
              'paymentMethod': tx.paymentMethodRaw,
              'cashReceived': tx.cashReceivedRaw,
              'items': tx.itemModels
                  .map((i) => {
                        'productId': i.productId,
                        'productName': i.productName,
                        'price': i.price,
                        'quantity': i.quantity,
                        'total': i.total,
                      })
                  .toList(),
            })
        .toList();

    return {
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'products': products,
      'shop': shop,
      'transactions': transactions,
    };
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
    await HiveDatabase.productBox.clear();
    await HiveDatabase.shopBox.clear();
    await HiveDatabase.transactionBox.clear();

    for (final p in (data['products'] as List).cast<Map<String, dynamic>>()) {
      final model = ProductModel(
        id: p['id'],
        name: p['name'],
        barcode: p['barcode'] ?? '',
        price: (p['price'] as num).toDouble(),
        stock: p['stock'] as int,
      );
      await HiveDatabase.productBox.put(model.id, model);
    }

    if (data['shop'] != null) {
      final s = data['shop'] as Map<String, dynamic>;
      await HiveDatabase.shopBox.put(
        _shopKey,
        ShopModel(
          name: s['name'] ?? '',
          addressLine1: s['addressLine1'] ?? '',
          addressLine2: s['addressLine2'] ?? '',
          phoneNumber: s['phoneNumber'] ?? '',
          upiId: s['upiId'] ?? '',
          footerText: s['footerText'] ?? '',
        ),
      );
    }

    for (final tx in (data['transactions'] as List).cast<Map<String, dynamic>>()) {
      final items = (tx['items'] as List)
          .cast<Map<String, dynamic>>()
          .map((i) => TransactionItemModel(
                productId: i['productId'],
                productName: i['productName'],
                price: (i['price'] as num).toDouble(),
                quantity: i['quantity'] as int,
                total: (i['total'] as num).toDouble(),
              ))
          .toList();

      final model = TransactionModel(
        id: tx['id'],
        createdAtMs: tx['createdAtMs'] as int,
        itemModels: items,
        totalAmount: (tx['totalAmount'] as num).toDouble(),
        invoiceNumberRaw: tx['invoiceNumber'] as String?,
        paymentMethodRaw: tx['paymentMethod'] as String?,
        cashReceivedRaw: tx['cashReceived'] != null
            ? (tx['cashReceived'] as num).toDouble()
            : null,
      );
      await HiveDatabase.transactionBox.put(model.id, model);
    }
  }
}
