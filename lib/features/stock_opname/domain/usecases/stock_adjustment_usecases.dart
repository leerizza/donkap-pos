import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/stock_adjustment.dart';
import '../repositories/stock_adjustment_repository.dart';

class GetStockAdjustmentsUseCase
    implements UseCase<List<StockAdjustment>, NoParams> {
  final StockAdjustmentRepository repository;

  GetStockAdjustmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<StockAdjustment>>> call(NoParams params) {
    return repository.getAdjustments();
  }
}

class SaveStockAdjustmentUseCase implements UseCase<void, StockAdjustment> {
  final StockAdjustmentRepository repository;

  SaveStockAdjustmentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(StockAdjustment params) {
    return repository.saveAdjustment(params);
  }
}
