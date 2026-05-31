import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/data/services/transaction_fake_service_impl.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:financial_tracker/helper/transaction_fake_repository.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionFakeServiceImpl _makeService({int numInstance = 3}) {
  return TransactionFakeServiceImpl(
    api: TransactionFakeRepository(numInstance: numInstance),
  );
}

void main() {
  group('TransactionFakeServiceImpl', () {
    // ── fetchAllTransacions ──────────────────────────────────────────────────
    group('fetchAllTransacions', () {
      test('retorna Success com lista de transações', () async {
        final service = _makeService(numInstance: 5);
        final result = await service.fetchAllTransacions();
        expect(result.isSuccess, isTrue);
        expect(result.successValueOrNull, hasLength(5));
      });

      test('retorna Error quando repositório está vazio', () async {
        final service = _makeService(numInstance: 0);
        final result = await service.fetchAllTransacions();
        expect(result.isFailure, isTrue);
        expect(result.failureValueOrNull, isA<DatasourceResultEmpty>());
      });
    });

    // ── storeTransacion ──────────────────────────────────────────────────────
    group('storeTransacion', () {
      test('retorna Success ao salvar transação válida', () async {
        final service = _makeService();
        final t = TransactionEntity.sampleIncome();
        final result = await service.storeTransacion(t);
        expect(result.isSuccess, isTrue);
      });

      test('lista cresce após salvar', () async {
        final service = _makeService(numInstance: 2);
        final t = TransactionEntity.sampleExpense();
        await service.storeTransacion(t);
        final all = await service.fetchAllTransacions();
        expect(all.successValueOrNull, hasLength(3));
      });
    });

    // ── removeTransacion ─────────────────────────────────────────────────────
    group('removeTransacion', () {
      test('retorna Success ao remover id existente', () async {
        final service = _makeService(numInstance: 2);
        final all = await service.fetchAllTransacions();
        final id = all.successValueOrNull!.first.id;

        final result = await service.removeTransacion(id);
        expect(result.isSuccess, isTrue);
      });

      test('retorna Error ao remover id inexistente', () async {
        final service = _makeService();
        final result = await service.removeTransacion('id-nao-existe');
        expect(result.isFailure, isTrue);
        expect(result.failureValueOrNull, isA<RecordNotFound>());
      });
    });

    // ── updateTransacion ─────────────────────────────────────────────────────
    group('updateTransacion', () {
      test('retorna Success ao editar transação existente', () async {
        final service = _makeService(numInstance: 2);
        final all = await service.fetchAllTransacions();
        final original = all.successValueOrNull!.first;
        final updated = original.copyWith(title: 'Editado', amount: 999.99);

        final result = await service.updateTransacion(updated);
        expect(result.isSuccess, isTrue);
      });

      test('retorna Error ao editar id inexistente', () async {
        final service = _makeService();
        final t = TransactionEntity.sampleIncome();
        final result = await service.updateTransacion(t);
        expect(result.isFailure, isTrue);
        expect(result.failureValueOrNull, isA<RecordNotFound>());
      });

      test('valor é de fato atualizado na lista', () async {
        final service = _makeService(numInstance: 1);
        final all = await service.fetchAllTransacions();
        final original = all.successValueOrNull!.first;
        final updated = original.copyWith(title: 'Novo Título', amount: 42.0);

        await service.updateTransacion(updated);

        final afterUpdate = await service.fetchAllTransacions();
        final found = afterUpdate.successValueOrNull!
            .firstWhere((t) => t.id == original.id);
        expect(found.title, equals('Novo Título'));
        expect(found.amount, equals(42.0));
      });
    });

    // ── fetchTransacionsByDate ────────────────────────────────────────────────
    group('fetchTransacionsByDate', () {
      test('retorna transações dentro do intervalo', () async {
        final service = _makeService(numInstance: 0);
        final t = TransactionEntity(
          title: 'Freelance',
          amount: 500,
          date: DateTime(2024, 3, 10),
          type: TransactionType.income,
        );
        await service.storeTransacion(t);

        final result = await service.fetchTransacionsByDate(
          DateTime(2024, 3, 1),
          DateTime(2024, 3, 31),
        );
        expect(result.isSuccess, isTrue);
        expect(result.successValueOrNull!.first.id, equals(t.id));
      });

      test('retorna Error quando nenhuma transação bate o filtro', () async {
        final service = _makeService(numInstance: 0);
        final t = TransactionEntity(
          title: 'Mercado',
          amount: 80,
          date: DateTime(2023, 1, 1),
          type: TransactionType.expense,
        );
        await service.storeTransacion(t);

        final result = await service.fetchTransacionsByDate(
          DateTime(2025, 1, 1),
          DateTime(2025, 12, 31),
        );
        expect(result.isFailure, isTrue);
        expect(result.failureValueOrNull, isA<DatasourceResultEmpty>());
      });
    });
  });
}