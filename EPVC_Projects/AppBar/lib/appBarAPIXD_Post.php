<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require_once('phpoffice/vendor/autoload.php');
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$servername = "localhost";
$username = "appbar";
$password = "apiappbar2024";
$dbname = "appbar";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
$conn->set_charset("utf8mb4");

$current_date = date("Y-m-d");

// Check connection
if ($conn->connect_error) {
    die(json_encode(array("message" => "Connection failed: " . $conn->connect_error)));
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $input = file_get_contents('php://input');
    $jsonData = json_decode($input, true);

    if ($jsonData && isset($jsonData['query_param']) && $jsonData['query_param'] == 2) {
        $requiredFields = ['name', 'vat', 'address', 'postalCode', 'city', 'country', 'email', 'phone'];
        foreach ($requiredFields as $field) {
            if (empty($jsonData[$field])) {
                echo json_encode(['success' => false, 'message' => 'Campo obrigatório em falta: ' . $field]);
                $conn->close();
                exit;
            }
        }

        // Enviar para a API externa
        $ch = curl_init('http://192.168.22.88/api/api.php');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($jsonData));
        $apiResponse = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        // Processar resposta da API externa
        if ($httpCode == 200 && $apiResponse) {
            $apiData = json_decode($apiResponse, true);

            if (isset($apiData['customer']['customerId']) && !empty($apiData['customer']['customerId'])) {
                $customerId = $apiData['customer']['customerId'];
                $email = $jsonData['email'];

                // Atualizar o campo IdXD na tabela ab_users
                $stmt = $conn->prepare("UPDATE ab_users SET IdXD = ? WHERE Email = ?");
                $stmt->bind_param("ss", $customerId, $email);
                $stmt->execute();
                $affected = $stmt->affected_rows;
                $stmt->close();
                // Adicionar info de debug à resposta
                $apiData['update_idxd'] = [
                  'email' => $email,
                  'customerId' => $customerId,
                  'affected_rows' => $affected
                ];
            }

            // Retornar a resposta da API externa (com debug extra se aplicável)
            echo json_encode($apiData);
        } else {
            echo json_encode(['success' => false, 'message' => 'Erro ao comunicar com a API externa.']);
        }
        $conn->close();
        exit;
    }
    // Novo: query_param 2.1
    else if ($jsonData && isset($jsonData['query_param']) && $jsonData['query_param'] == 2.1) {
        if (empty($jsonData['vat'])) {
            echo json_encode(['success' => false, 'message' => 'Campo obrigatório em falta: vat']);
            $conn->close();
            exit;
        }
        // Enviar para a API externa
        $ch = curl_init('http://192.168.22.88/api/api.php');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($jsonData));
        $apiResponse = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode == 200 && $apiResponse) {
            echo $apiResponse;
        } else {
            echo json_encode(['success' => false, 'message' => 'Erro ao comunicar com a API externa.']);
        }
        $conn->close();
        exit;
    }
    else {
        echo json_encode(['success' => false, 'message' => 'Formato ou parâmetros inválidos.']);
        $conn->close();
        exit;
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Método não permitido.']);
    $conn->close();
    exit;
}

?>