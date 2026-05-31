import 'dart:convert';

import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/errors/errors_messagens.dart';

import '../domain/entity/transaction_entity.dart';

import 'transaction_fake_factory.dart';

class TransactionFakeRepository {
  late List<TransactionEntity> transactions;

  /// [simulateErrors]: se true, addData lança erros aleatórios (comportamento
  /// original de produção). Se false (padrão em testes), sempre salva.
  final bool simulateErrors;

  TransactionFakeRepository({int numInstance = 10, this.simulateErrors = false}) {
    transactions = List.generate(
      numInstance,
      (index) => TransactionFakeFactory.factory(),
    );
  }

  Future<String> getData() async {
    return (transactions.isEmpty)
        ? throw DatasourceResultEmpty(MessagesError.emptySharedP)
        : jsonEncode(transactions.map((e) => e.toMap()).toList());
  }

  Future<void> deleteData(String id) async {
    final index = transactions.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw RecordNotFound(MessagesError.recordNotFound);
    }
    transactions.removeAt(index);
  }

  Future<void> addData(String transactionJson) async {
    await Future.delayed(const Duration(milliseconds: 10));

    if (transactionJson.isEmpty) {
      throw InvalidData(MessagesError.recordInvalidFormat);
    }

    transactions.add(TransactionEntity.fromMap(jsonDecode(transactionJson)));
  }

  Future<String> getDataByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final filteredTransactions = transactions.where((transaction) {
      return transaction.date.isAfter(
            startDate.subtract(const Duration(seconds: 1)),
          ) &&
          transaction.date.isBefore(
            endDate.add(const Duration(seconds: 1)),
          );
    }).toList();

    if (filteredTransactions.isEmpty) {
      throw DatasourceResultEmpty(MessagesError.emptySearch);
    }

    return jsonEncode(filteredTransactions.map((e) => e.toMap()).toList());
  }

  Future<void> updateData(String transactionJson) async {
    await Future.delayed(const Duration(milliseconds: 10));

    if (transactionJson.isEmpty) {
      throw InvalidData(MessagesError.recordInvalidFormat);
    }

    final updated = TransactionEntity.fromMap(jsonDecode(transactionJson));
    final index = transactions.indexWhere((e) => e.id == updated.id);

    if (index == -1) {
      throw RecordNotFound(MessagesError.recordNotFound);
    }

    transactions[index] = updated;
  }
}