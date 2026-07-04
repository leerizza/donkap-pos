import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/stock_adjustment.dart';
import '../../domain/repositories/stock_adjustment_repository.dart';
import '../models/stock_adjustment_model.dart';

class StockAdjustmentRepositoryImpl implements StockAdjustmentRepository {
  @override
  Future<Either<Failure, List<StockAdjustment>>> getAdjustments() async {
    try {
      final box = HiveDatabase.stockAdjustmentBox;
      final adjustments = box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(adjustments);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveAdjustment(
      StockAdjustment adjustment) async {
    try {
      final box = HiveDatabase.stockAdjustmentBox;
      final model = StockAdjustmentModel.fromEntity(adjustment);
      await box.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
