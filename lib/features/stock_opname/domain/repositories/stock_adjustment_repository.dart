import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/stock_adjustment.dart';

abstract class StockAdjustmentRepository {
  Future<Either<Failure, List<StockAdjustment>>> getAdjustments();
  Future<Either<Failure, void>> saveAdjustment(StockAdjustment adjustment);
}
