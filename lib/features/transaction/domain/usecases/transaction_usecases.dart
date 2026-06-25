import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class SaveTransactionUseCase implements UseCase<void, Transaction> {
  final TransactionRepository repository;
  SaveTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Transaction params) =>
      repository.saveTransaction(params);
}

class GetTransactionsUseCase implements UseCase<List<Transaction>, NoParams> {
  final TransactionRepository repository;
  GetTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(NoParams params) =>
      repository.getTransactions();
}

class DeleteTransactionUseCase implements UseCase<void, String> {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) =>
      repository.deleteTransaction(params);
}
