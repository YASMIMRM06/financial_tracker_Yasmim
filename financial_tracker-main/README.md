# financial_tracker

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Vou ler os dois projetos para comparar com o que fizemos:Tenho todos os arquivos alterados. Agora vou ler cada par e gerar os arquivos comentados:Tenho tudo. Agora vou gerar os arquivos comentados como se você estivesse explicando para si mesma:9 arquivos comentados, na ordem das camadas de baixo para cima. Aqui está o resumo do que explicar para o professor:

---

**O fio condutor de tudo que fizemos: a funcionalidade de edição**

O projeto usa Clean Architecture — cada coisa tem seu lugar. Para adicionar a edição, precisei passar por todas as camadas na ordem:

| Camada | Arquivo | O que mudei |
|---|---|---|
| **Datasource** | `transaction_fake_repository` | Adicionei `updateData()` + removi o `Random()` que quebrava testes |
| **Contrato do serviço** | `transaction_storage_contract` | Adicionei a assinatura `updateTransacion()` |
| **Serviço** | `transaction_fake_service_impl` | Implementei `updateTransacion()` + tornei o repositório injetável para testes |
| **Contrato do repositório** | `transaction_repository_contract` | Adicionei a assinatura `updateTransacion()` |
| **Repositório** | `transaction_repository_impl` | Implementei delegando para o serviço |
| **UseCase** ⭐ novo | `update_transaction_use_case_impl` | Arquivo novo seguindo o padrão existente |
| **Facade** | `use_case_facade` | Registrei o novo UseCase |
| **Injeção de dependência** | `dependencies` | Registrei o UseCase no container |
| **Controller** | `home_page_controller` | Adicionei `editTransaction` Command + `_editTransaction` que atualiza o signal in-place |

