<?php
header('Content-Type: application/json');

// Configurações do banco de dados
$host = 'localhost';
$dbname = 'appbar';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die(json_encode(['status' => 'error', 'message' => 'Erro de conexão: ' . $e->getMessage()]));
}

// Receber os dados do webhook do SIBS
$data = json_decode(file_get_contents('php://input'), true);

if ($data) {
    $orderId = $data['orderId'] ?? null;
    $paymentId = $data['paymentId'] ?? null;
    $status = $data['status'] ?? null;

    if ($orderId && $status === 'SUCCESS') {
        try {
            // Atualizar o status do pedido no banco de dados
            $stmt = $pdo->prepare("UPDATE pedidos SET status = 'paid', payment_id = ? WHERE order_number = ?");
            $stmt->execute([$paymentId, $orderId]);

            echo json_encode([
                'status' => 'success',
                'message' => 'Pagamento processado com sucesso'
            ]);
        } catch(PDOException $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'Erro ao atualizar pedido: ' . $e->getMessage()
            ]);
        }
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'Dados inválidos ou pagamento não bem-sucedido'
        ]);
    }
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Nenhum dado recebido'
    ]);
}
?> 