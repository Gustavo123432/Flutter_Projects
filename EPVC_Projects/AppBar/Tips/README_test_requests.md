# Requisições de Teste para API de Faturação

Este diretório contém requisições de teste para verificar se a API está funcionando corretamente com os novos campos de faturação.

## Arquivos de Teste

### 1. `test_request.raw` - Fatura com NIF
**Cenário:** Cliente solicita fatura com NIF válido
- **requestInvoice:** 1 (sim)
- **nif:** 123456789
- **documentType:** FR (Fatura-Recibo)
- **idUser:** 0 (faturação manual)
- **customerVAT:** 123456789

### 2. `test_request_simple.raw` - Fatura Simplificada
**Cenário:** Cliente não solicita fatura ou solicita fatura simplificada
- **requestInvoice:** 0 (não)
- **nif:** vazio
- **documentType:** FS (Fatura Simplificada)
- **idUser:** 0
- **customerVAT:** 999999990

### 3. `test_request_auto.raw` - Faturação Automática
**Cenário:** Cliente com faturação automática ativada
- **requestInvoice:** 1 (sim)
- **nif:** 987654321
- **documentType:** FR (Fatura-Recibo)
- **idUser:** 456789 (idXD do utilizador)
- **customerVAT:** 987654321

## Como Usar

### No Postman:
1. Importe o arquivo `.raw` correspondente
2. Ajuste a URL se necessário
3. Execute a requisição
4. Verifique a resposta JSON

### No Insomnia:
1. Crie uma nova requisição POST
2. Cole o conteúdo do arquivo `.raw`
3. Execute e verifique a resposta

### No cURL:
```bash
curl -X POST https://appbar.epvc.pt/API/appBarAPI_GET.php \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "query_param=5&nome=João&apelido=Silva&..."
```

## Resposta Esperada

**Sucesso:**
```json
{
  "status": "success",
  "message": "Pedido adicionado com sucesso.",
  "orderNumber": 1234
}
```

**Erro:**
```json
{
  "status": "error",
  "message": "Erro ao adicionar o pedido: [detalhes do erro]"
}
```

## Campos Obrigatórios

- `query_param` = 5
- `nome`
- `apelido`
- `turma`
- `descricao`
- `permissao`
- `total`
- `valor`
- `imagem`
- `payment_method`
- `phone_number`

## Novos Campos de Faturação

- `requestInvoice` - Se solicita fatura (1/0)
- `nif` - NIF do cliente
- `documentType` - Tipo de documento (FR/FS)
- `idUser` - ID do utilizador para faturação automática
- `customerName` - Nome completo
- `customerAddress` - Morada
- `customerPostalCode` - Código postal
- `customerCity` - Cidade
- `customerCountry` - País (sempre PT)
- `customerVAT` - NIF para faturação
- `cartItems` - JSON com itens do carrinho
- `dinheiroAtual` - Valor entregue

## Verificação na Base de Dados

Após executar a requisição, verifique se os dados foram inseridos corretamente:

```sql
SELECT * FROM ab_pedidos WHERE NPedido = [orderNumber];
```

Todos os novos campos devem estar preenchidos conforme os valores enviados na requisição. 