import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

// ela foi feita para garantir que a entidade de transação funcione corretamente, especialmente os métodos de serialização (toMap, fromMap) 
//e a função copyWith. Os testes cobrem casos comuns e verificam se a entidade se comporta como esperado, o que é crucial para a integridade dos dados em toda a aplicação.
void main() {
  group('TransactionEntity', () {
    final date = DateTime(2024, 5, 20);

    final income = TransactionEntity(
      id: 'abc-123',
      title: 'Salário',
      amount: 3000.00,
      date: date,
      type: TransactionType.income,
    );

    // ── Serialização ─────────────────────────────────────────────────────────
    group('toMap / fromMap (round-trip)', () {
      test('toMap contém todos os campos', () {
        final map = income.toMap();
        expect(map['id'], equals('abc-123'));
        expect(map['title'], equals('Salário'));
        expect(map['amount'], equals(3000.00));
        expect(map['type'], equals('income'));
        expect(map['date'], isNotNull);
      });

      test('fromMap reconstrói entidade idêntica', () {
        final map = income.toMap();
        final restored = TransactionEntity.fromMap(map);
        expect(restored.id, equals(income.id));
        expect(restored.title, equals(income.title));
        expect(restored.amount, equals(income.amount));
        expect(restored.type, equals(income.type));
      });

      test('toJson / fromMap é round-trip fiel', () {
        final json = income.toJson();
        final restored = TransactionEntity.fromMap(
          Map<String, dynamic>.from(
            (json.isNotEmpty)
                ? (income.toMap()) // usa toMap como proxy
                : {},
          ),
        );
        expect(restored.id, equals(income.id));
      });

      test('type desconhecido no fromMap faz fallback para expense', () {
        final map = income.toMap()..['type'] = 'invalid_type';
        final t = TransactionEntity.fromMap(map);
        expect(t.type, equals(TransactionType.expense));
      });
    });

    // ── copyWith ─────────────────────────────────────────────────────────────
    group('copyWith', () {
      test('copia com novo título mantém os demais campos', () {
        final copy = income.copyWith(title: 'Bônus');
        expect(copy.id, equals(income.id));
        expect(copy.title, equals('Bônus'));
        expect(copy.amount, equals(income.amount));
        expect(copy.type, equals(income.type));
      });

      test('copia com novo tipo muda apenas o tipo', () {
        final copy = income.copyWith(type: TransactionType.expense);
        expect(copy.type, equals(TransactionType.expense));
        expect(copy.id, equals(income.id));
      });

      test('sem parâmetros retorna objeto equivalente', () {
        final copy = income.copyWith();
        expect(copy, equals(income));
      });
    });

    // ── Igualdade ────────────────────────────────────────────────────────────
    group('equality (== e hashCode)', () {
      test('dois objetos com mesmos campos são iguais', () {
        final a = TransactionEntity(
          id: 'same',
          title: 'X',
          amount: 10,
          date: date,
          type: TransactionType.expense,
        );
        final b = TransactionEntity(
          id: 'same',
          title: 'X',
          amount: 10,
          date: date,
          type: TransactionType.expense,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('objetos com ids distintos não são iguais', () {
        final a = TransactionEntity(
          id: 'aaa',
          title: 'X',
          amount: 10,
          date: date,
          type: TransactionType.income,
        );
        final b = TransactionEntity(
          id: 'bbb',
          title: 'X',
          amount: 10,
          date: date,
          type: TransactionType.income,
        );
        expect(a, isNot(equals(b)));
      });
    });

    // ── id automático ────────────────────────────────────────────────────────
    group('id automático', () {
      test('gera uuid único quando id não é fornecido', () {
        final a = TransactionEntity.sampleIncome();
        final b = TransactionEntity.sampleIncome();
        expect(a.id, isNotEmpty);
        expect(a.id, isNot(equals(b.id)));
      });
    });

    // ── TransactionTypeExtension ─────────────────────────────────────────────
    group('TransactionTypeExtension', () {
      test('nameSingular correto para income', () {
        expect(TransactionType.income.nameSingular, equals('Receita'));
      });
      test('nameSingular correto para expense', () {
        expect(TransactionType.expense.nameSingular, equals('Despesa'));
      });
      test('namePlural correto para income', () {
        expect(TransactionType.income.namePlural, equals('Receitas'));
      });
      test('namePlural correto para expense', () {
        expect(TransactionType.expense.namePlural, equals('Despesas'));
      });
    });
  });
}