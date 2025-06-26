<?php
header('Content-Type: application/json');

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $input = file_get_contents('php://input');
    $jsonData = json_decode($input, true);

    if ($jsonData && isset($jsonData['query_param']) && $jsonData['query_param'] == 2) {
        $requiredFields = ['name', 'vat', 'address', 'postalCode', 'city', 'country', 'email', 'phone'];
        foreach ($requiredFields as $field) {
            if (empty($jsonData[$field])) {
                echo json_encode(['success' => false, 'message' => 'Campo obrigatório em falta: ' . $field]);
                exit;
            }
        }
        // Aqui seria feita a lógica de integração com o sistema XD, se necessário
        echo json_encode(['success' => true, 'message' => 'Utilizador recebido com sucesso (simulação, sem BD).']);
        exit;
    } else {
        echo json_encode(['success' => false, 'message' => 'Formato ou parâmetros inválidos.']);
        exit;
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Método não permitido.']);
    exit;
} 