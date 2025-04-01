<?php
header('Content-Type: application/json');

// Configurações do banco de dados
$host = 'localhost';
$dbname = 'appbar';
$username = 'root';
$password = '';

// Configurações do SIBS
$webhookSecret = 'SEU_WEBHOOK_SECRET_AQUI'; // Substitua pelo Secret do Webhook do SIBS

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die(json_encode(['status' => 'error', 'message' => 'Erro de conexão: ' . $e->getMessage()]));
}

// Verificar se é uma requisição POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['status' => 'error', 'message' => 'Método não permitido']));
}

// Obter os headers do SIBS
$iv = $_SERVER['HTTP_X_INITIALIZATION_VECTOR'] ?? '';
$tag = $_SERVER['HTTP_X_AUTHENTICATION_TAG'] ?? '';

// Obter o corpo da requisição
$encryptedData = file_get_contents('php://input');

// Verificar se todos os headers necessários estão presentes
if (empty($iv) || empty($tag)) {
    http_response_code(400);
    die(json_encode(['status' => 'error', 'message' => 'Headers inválidos']));
}

try {
    // Decriptar os dados usando o Webhook Secret
    $decryptedData = openssl_decrypt(
        $encryptedData,
        'AES-256-GCM',
        $webhookSecret,
        OPENSSL_RAW_DATA,
        base64_decode($iv),
        base64_decode($tag)
    );

    if ($decryptedData === false) {
        throw new Exception('Falha ao decriptar os dados');
    }

    // Decodificar os dados JSON
    $data = json_decode($decryptedData, true);

    if (!$data) {
        throw new Exception('Dados JSON inválidos');
    }

    // Processar a notificação
    $orderId = $data['orderId'] ?? null;
    $paymentId = $data['paymentId'] ?? null;
    $status = $data['status'] ?? null;

    if (!$orderId || !$paymentId || !$status) {
        throw new Exception('Dados incompletos');
    }

    // Atualizar o status do pedido no banco de dados
    $stmt = $pdo->prepare("UPDATE pedidos SET status = ?, payment_id = ? WHERE order_number = ?");
    
    switch ($status) {
        case 'SUCCESS':
            $dbStatus = 'paid';
            break;
        case 'CANCELLED':
            $dbStatus = 'cancelled';
            break;
        default:
            $dbStatus = 'pending';
    }

    $stmt->execute([$dbStatus, $paymentId, $orderId]);

    // Responder com sucesso
    echo json_encode([
        'status' => 'success',
        'message' => 'Webhook processado com sucesso'
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 