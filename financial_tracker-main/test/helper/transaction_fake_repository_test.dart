import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:financial_tracker/helper/transaction_fake_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionFakeRepository', () {
    late TransactionFakeRepository repo;

    setUp(() {
      repo = TransactionFakeRepository(numInstance: 3);
    });

    // ── getData ──────────────────────────────────────────────────────────────
    group('getData', () {
      test('retorna JSON com as transações iniciais', () async {
        final result = await repo.getData();
        expect(result, isNotEmpty);
        expect(result, contains('"id"'));
      });

      test('lança DatasourceResultEmpty quando a lista está vazia', () async {
        repo.transactions.clear();
        expect(repo.getData(), throwsA(isA<DatasourceResultEmpty>()));
      });
    });

    // ── addData ──────────────────────────────────────────────────────────────
    group('addData', () {
      test('adiciona transação com JSON válido', () async {
        final before = repo.transactions.length;
        final t = TransactionEntity.sampleIncome();
        await repo.addData(t.toJson());
        expect(repo.transactions.length, equals(before + 1));
        expect(repo.transactions.last.id, equals(t.id));
      });

      test('lança InvalidData com JSON vazio', () {
        expect(repo.addData(''), throwsA(isA<InvalidData>()));
      });
    });

    // ── deleteData ───────────────────────────────────────────────────────────
    group('deleteData', () {
      test('remove transação existente pelo id', () async {
        final id = repo.transactions.first.id;
        final before = repo.transactions.length;
        await repo.deleteData(id);
        expect(repo.transactions.length, equals(before - 1));
        expect(repo.transactions.any((t) => t.id == id), isFalse);
      });

      test('lança RecordNotFound para id inexistente', () {
        expect(
          repo.deleteData('id-que-nao-existe'),
          throwsA(isA<RecordNotFound>()),
        );
      });
    });

    // ── updateData ───────────────────────────────────────────────────────────
    group('updateData', () {
      test('atualiza título de transação existente', () async {
        final original = repo.transactions.first;
        final updated = original.copyWith(title: 'Título Atualizado');
        await repo.updateData(updated.toJson());
        expect(repo.transactions.first.title, equals('Título Atualizado'));
      });

      test('lança RecordNotFound para id inexistente', () {
        final t = TransactionEntity.sampleExpense();
        expect(repo.updateData(t.toJson()), throwsA(isA<RecordNotFound>()));
      });

      test('lança InvalidData com JSON vazio', () {
        expect(repo.updateData(''), throwsA(isA<InvalidData>()));
      });
    });

    // ── getDataByDateRange ───────────────────────────────────────────────────
    group('getDataByDateRange', () {
      test('retorna transações dentro do intervalo', () async {
        final t = TransactionEntity(
          title: 'Salário',
          amount: 1000,
          date: DateTime(2024, 6, 15),
          type: TransactionType.income,
        );
        repo.transactions = [t];

        final result = await repo.getDataByDateRange(
          DateTime(2024, 6, 1),
          DateTime(2024, 6, 30),
        );
        expect(result, contains(t.id));
      });

      test('lança DatasourceResultEmpty quando nenhuma transação bate o filtro',
          () {
        repo.transactions = [
          TransactionEntity(
            title: 'Mercado',
            amount: 50,
            date: DateTime(2024, 1, 1),
            type: TransactionType.expense,
          ),
        ];

        expect(
          repo.getDataByDateRange(DateTime(2025, 1, 1), DateTime(2025, 12, 31)),
          throwsA(isA<DatasourceResultEmpty>()),
        );
      });
    });
  });
}