import 'package:financial_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:financial_tracker/data/services/transaction_fake_service_impl.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:financial_tracker/domain/usecase/add_transaction_use_case_impl.dart';
import 'package:financial_tracker/domain/usecase/delete_transaction_use_case_impl.dart';
import 'package:financial_tracker/domain/usecase/get_all_%20transactions_use_case_impl.dart';
import 'package:financial_tracker/domain/usecase/get_transaction_by_date_use_case_impl.dart';
import 'package:financial_tracker/domain/usecase/update_transaction_use_case_impl.dart';
import 'package:financial_tracker/helper/transaction_fake_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta o stack completo: FakeRepo → Service → RepositoryImpl
TransactionRepositoryImpl _makeRepo({int numInstance = 3}) {
  final fakeRepo = TransactionFakeRepository(numInstance: numInstance);
  final service = TransactionFakeServiceImpl(api: fakeRepo);
  return TransactionRepositoryImpl(dataSource: service);
}

void main() {
  // ── GetAllTransactionsUseCaseImpl ─────────────────────────────────────────
  group('GetAllTransactionsUseCaseImpl', () {
    test('retorna lista com todas as transações', () async {
      final repo = _makeRepo(numInstance: 4);
      final useCase = GetAllTransactionsUseCaseImpl(repo);

      final result = await useCase.call(());
      expect(result.isSuccess, isTrue);
      expect(result.successValueOrNull, hasLength(4));
    });

    test('retorna falha quando não há transações', () async {
      final repo = _makeRepo(numInstance: 0);
      final useCase = GetAllTransactionsUseCaseImpl(repo);

      final result = await useCase.call(());
      expect(result.isFailure, isTrue);
    });
  });

  // ── AddTransactionUseCaseImpl ─────────────────────────────────────────────
  group('AddTransactionUseCaseImpl', () {
    test('adiciona receita com sucesso', () async {
      final repo = _makeRepo(numInstance: 0);
      final addUseCase = AddTransactionUseCaseImpl(repo);
      final getAll = GetAllTransactionsUseCaseImpl(repo);

      final t = TransactionEntity.sampleIncome();
      final result = await addUseCase.call((transaction: t));
      expect(result.isSuccess, isTrue);

      final all = await getAll.call(());
      expect(all.successValueOrNull, hasLength(1));
      expect(all.successValueOrNull!.first.id, equals(t.id));
    });

    test('adiciona despesa com sucesso', () async {
      final repo = _makeRepo(numInstance: 0);
      final addUseCase = AddTransactionUseCaseImpl(repo);

      final t = TransactionEntity.sampleExpense();
      final result = await addUseCase.call((transaction: t));
      expect(result.isSuccess, isTrue);
    });

    test('múltiplas adições acumulam na lista', () async {
      final repo = _makeRepo(numInstance: 0);
      final addUseCase = AddTransactionUseCaseImpl(repo);
      final getAll = GetAllTransactionsUseCaseImpl(repo);

      await addUseCase.call((transaction: TransactionEntity.sampleIncome()));
      await addUseCase.call((transaction: TransactionEntity.sampleExpense()));
      await addUseCase.call((transaction: TransactionEntity.sampleIncome()));

      final all = await getAll.call(());
      expect(all.successValueOrNull, hasLength(3));
    });
  });

  // ── DeleteTransactionUseCaseImpl ──────────────────────────────────────────
  group('DeleteTransactionUseCaseImpl', () {
    test('remove transação existente', () async {
      final repo = _makeRepo(numInstance: 2);
      final deleteUseCase = DeleteTransactionUseCaseImpl(repo);
      final getAll = GetAllTransactionsUseCaseImpl(repo);

      final all = await getAll.call(());
      final id = all.successValueOrNull!.first.id;

      final result = await deleteUseCase.call((id: id));
      expect(result.isSuccess, isTrue);

      final after = await getAll.call(());
      expect(after.successValueOrNull, hasLength(1));
      expect(after.successValueOrNull!.any((t) => t.id == id), isFalse);
    });

    test('retorna falha para id inexistente', () async {
      final repo = _makeRepo(numInstance: 2);
      final deleteUseCase = DeleteTransactionUseCaseImpl(repo);

      final result = await deleteUseCase.call((id: 'nao-existe'));
      expect(result.isFailure, isTrue);
    });
  });

  // ── UpdateTransactionUseCaseImpl ──────────────────────────────────────────
  group('UpdateTransactionUseCaseImpl', () {
    test('atualiza título e valor de transação existente', () async {
      final repo = _makeRepo(numInstance: 1);
      final updateUseCase = UpdateTransactionUseCaseImpl(repo);
      final getAll = GetAllTransactionsUseCaseImpl(repo);

      final original = (await getAll.call(())).successValueOrNull!.first;
      final updated = original.copyWith(title: 'Atualizado', amount: 777.77);

      final result = await updateUseCase.call((transaction: updated));
      expect(result.isSuccess, isTrue);

      final after = await getAll.call(());
      final found =
          after.successValueOrNull!.firstWhere((t) => t.id == original.id);
      expect(found.title, equals('Atualizado'));
      expect(found.amount, equals(777.77));
    });

    test('mantém mesmo id após update', () async {
      final repo = _makeRepo(numInstance: 1);
      final updateUseCase = UpdateTransactionUseCaseImpl(repo);
      final getAll = GetAllTransactionsUseCaseImpl(repo);

      final original = (await getAll.call(())).successValueOrNull!.first;
      final updated = original.copyWith(title: 'Novo nome');
      await updateUseCase.call((transaction: updated));

      final after = await getAll.call(());
      expect(after.successValueOrNull!.first.id, equals(original.id));
    });

    test('retorna falha para id inexistente', () async {
      final repo = _makeRepo(numInstance: 2);
      final updateUseCase = UpdateTransactionUseCaseImpl(repo);

      final t = TransactionEntity.sampleIncome(); // id novo, não existe
      final result = await updateUseCase.call((transaction: t));
      expect(result.isFailure, isTrue);
    });
  });

  // ── GetTransactionBayDateUseCaseImpl ──────────────────────────────────────
  group('GetTransactionBayDateUseCaseImpl', () {
    test('filtra transações pelo intervalo de datas', () async {
      final repo = _makeRepo(numInstance: 0);
      final addUseCase = AddTransactionUseCaseImpl(repo);
      final dateUseCase = GetTransactionBayDateUseCaseImpl(repo);

      final inside = TransactionEntity(
        title: 'Dentro do intervalo',
        amount: 100,
        date: DateTime(2024, 6, 15),
        type: TransactionType.income,
      );
      final outside = TransactionEntity(
        title: 'Fora do intervalo',
        amount: 50,
        date: DateTime(2023, 1, 1),
        type: TransactionType.expense,
      );

      await addUseCase.call((transaction: inside));
      await addUseCase.call((transaction: outside));

      final result = await dateUseCase.call((
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 30),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.successValueOrNull, hasLength(1));
      expect(result.successValueOrNull!.first.id, equals(inside.id));
    });

    test('retorna falha quando nenhuma transação está no intervalo', () async {
      final repo = _makeRepo(numInstance: 0);
      final addUseCase = AddTransactionUseCaseImpl(repo);
      final dateUseCase = GetTransactionBayDateUseCaseImpl(repo);

      await addUseCase.call((
        transaction: TransactionEntity(
          title: 'Antigo',
          amount: 200,
          date: DateTime(2022, 1, 1),
          type: TransactionType.expense,
        ),
      ));

      final result = await dateUseCase.call((
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
      ));

      expect(result.isFailure, isTrue);
    });
  });
}