import 'package:hive_flutter/hive_flutter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/transaction/data/models/transaction_item_model.dart';
import '../../features/transaction/data/models/transaction_model.dart';
import '../../features/stock_opname/data/models/stock_adjustment_model.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String transactionBoxName = 'transactions';
  static const String stockAdjustmentBoxName = 'stock_adjustments';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(ShopModelAdapter());
    Hive.registerAdapter(TransactionItemModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(StockAdjustmentModelAdapter());

    // Open Boxes
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<TransactionModel>(transactionBoxName);
    await Hive.openBox<StockAdjustmentModel>(stockAdjustmentBoxName);
  }

  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(productBoxName);
  static Box<ShopModel> get shopBox => Hive.box<ShopModel>(shopBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box<TransactionModel> get transactionBox =>
      Hive.box<TransactionModel>(transactionBoxName);
  static Box<StockAdjustmentModel> get stockAdjustmentBox =>
      Hive.box<StockAdjustmentModel>(stockAdjustmentBoxName);
}
