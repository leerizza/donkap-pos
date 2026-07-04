import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/stock_adjustment.dart';
import '../../domain/usecases/stock_adjustment_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'stock_adjustment_event.dart';
part 'stock_adjustment_state.dart';

class StockAdjustmentBloc
    extends Bloc<StockAdjustmentEvent, StockAdjustmentState> {
  final GetStockAdjustmentsUseCase getStockAdjustmentsUseCase;
  final SaveStockAdjustmentUseCase saveStockAdjustmentUseCase;

  StockAdjustmentBloc({
    required this.getStockAdjustmentsUseCase,
    required this.saveStockAdjustmentUseCase,
  }) : super(const StockAdjustmentState()) {
    on<LoadStockAdjustments>(_onLoad);
    on<SaveStockAdjustment>(_onSave);
  }

  Future<void> _onLoad(
      LoadStockAdjustments event, Emitter<StockAdjustmentState> emit) async {
    emit(state.copyWith(status: StockAdjustmentStatus.loading));
    final result = await getStockAdjustmentsUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
          status: StockAdjustmentStatus.error, message: failure.message)),
      (adjustments) => emit(state.copyWith(
          status: StockAdjustmentStatus.loaded, adjustments: adjustments)),
    );
  }

  Future<void> _onSave(
      SaveStockAdjustment event, Emitter<StockAdjustmentState> emit) async {
    final result = await saveStockAdjustmentUseCase(event.adjustment);
    result.fold(
      (failure) => emit(state.copyWith(
          status: StockAdjustmentStatus.error, message: failure.message)),
      (_) {
        emit(state.copyWith(
            status: StockAdjustmentStatus.success,
            message: 'Penyesuaian stok disimpan'));
        add(LoadStockAdjustments());
      },
    );
  }
}
