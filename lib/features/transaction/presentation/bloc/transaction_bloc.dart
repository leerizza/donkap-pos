import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final SaveTransactionUseCase saveTransactionUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  TransactionBloc({
    required this.saveTransactionUseCase,
    required this.getTransactionsUseCase,
    required this.deleteTransactionUseCase,
  }) : super(TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoad);
    on<SaveTransactionEvent>(_onSave);
    on<DeleteTransactionEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadTransactionsEvent event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    final result = await getTransactionsUseCase(NoParams());
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionLoaded(transactions)),
    );
  }

  Future<void> _onSave(
      SaveTransactionEvent event, Emitter<TransactionState> emit) async {
    final result = await saveTransactionUseCase(event.transaction);
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (_) => add(const LoadTransactionsEvent()),
    );
  }

  Future<void> _onDelete(
      DeleteTransactionEvent event, Emitter<TransactionState> emit) async {
    final result = await deleteTransactionUseCase(event.id);
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (_) => add(const LoadTransactionsEvent()),
    );
  }
}
