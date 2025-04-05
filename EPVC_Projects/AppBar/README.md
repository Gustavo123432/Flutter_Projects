# AppBar EPVC

Aplicativo de gestão para o bar da EPVC (Escola Profissional de Vila do Conde).

## Funcionalidades

- Sistema de login para diferentes tipos de usuários
- Módulo para alunos
- Módulo para administração
- Módulo para bar
- Integração com pagamentos SIBS (MB WAY, Multibanco)

## Integração com SIBS

O projeto inclui integração com a API SIBS para processamento de pagamentos. Para configurar:

1. Crie um arquivo `.env` na raiz do projeto baseado no `.env.sample`
2. Preencha as credenciais de API da SIBS:
   ```
   SIBS_BEARER_TOKEN=seu_token_aqui
   SIBS_CLIENT_ID=seu_client_id_aqui
   SIBS_TERMINAL_ID=seu_terminal_id_aqui
   ```

3. Se o arquivo `.env` não for encontrado, o aplicativo funcionará em modo de simulação.

### Modo de Simulação

O modo de simulação permite testar o fluxo de pagamento sem necessidade de credenciais reais da SIBS.
Para alternar entre o modo real e de simulação, modifique a flag `_useTestMode` em `lib/SIBS/payment_example.dart`.

## Configuração do Projeto

```bash
# Instalar dependências
flutter pub get

# Executar o aplicativo
flutter run
```

## Recursos

Para ajuda com o desenvolvimento Flutter, visite a [documentação online](https://docs.flutter.dev/), que oferece tutoriais, exemplos e referência completa da API.
