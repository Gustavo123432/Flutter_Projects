//////////////////////////////////
///  5) Add Pedido      	   ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "POST" && $_POST['query_param'] == 5 && isset($_POST['nome']) && isset($_POST['imagem']) && isset($_POST['apelido']) && isset($_POST['permissao']) && isset($_POST['valor']) && isset($_POST['turma']) && isset($_POST['descricao']) && isset($_POST['total']) && isset($_POST['payment_method']) && isset($_POST['phone_number'])) {
    $nome = $_POST['nome'];
    $apelido = $_POST['apelido'];
    $turma = $_POST['turma'];
    $descricao = $_POST['descricao'];
    $permissao = $_POST['permissao'];
    $total = $_POST['total'];
    $valor = $_POST['valor'];
    $imagem = $_POST['imagem'];
    $phone = $_POST['payment_method'];
    $metodoPagamento = $_POST['phone_number'];
    
    // Novos campos de faturação
    $requestInvoice = isset($_POST['requestInvoice']) ? $_POST['requestInvoice'] : '0';
    $nif = isset($_POST['nif']) ? $_POST['nif'] : '';
    $documentType = isset($_POST['documentType']) ? $_POST['documentType'] : 'FS';
    $idUser = isset($_POST['idUser']) ? $_POST['idUser'] : '0';
    $customerName = isset($_POST['customerName']) ? $_POST['customerName'] : '';
    $customerAddress = isset($_POST['customerAddress']) ? $_POST['customerAddress'] : '';
    $customerPostalCode = isset($_POST['customerPostalCode']) ? $_POST['customerPostalCode'] : '';
    $customerCity = isset($_POST['customerCity']) ? $_POST['customerCity'] : '';
    $customerCountry = isset($_POST['customerCountry']) ? $_POST['customerCountry'] : 'PT';
    $customerVAT = isset($_POST['customerVAT']) ? $_POST['customerVAT'] : '';

    if ($valor == 0) {
        $valor = 0;
    } else {
        $valor = $valor - $total;
    }

    date_default_timezone_set('Europe/Lisbon');
    $currentDate = date('Y-m-d');
    $currentTime = date('H:i:s');

    $nomeCompleto = $nome . " " . $apelido;

    // Generate a new order number between 1000 and 9999
    $newOrderNumber = rand(1000, 9999);

    // Check if the generated number already exists in the database
    $checkSql = "SELECT NPedido FROM ab_pedidos WHERE NPedido = '$newOrderNumber'";
    $checkResult = $conn->query($checkSql);

    // If the number exists, generate a new one until we find a unique one
    while ($checkResult && $checkResult->num_rows > 0) {
        $newOrderNumber = rand(1000, 9999);
        $checkResult = $conn->query("SELECT NPedido FROM ab_pedidos WHERE NPedido = '$newOrderNumber'");
    }

    // Prepare and execute the SQL query to insert the order details with the new order number and faturação fields
    $sql = "INSERT INTO ab_pedidos (
        NPedido, 
        QPediu, 
        Turma, 
        Permissao, 
        Descricao, 
        Imagem, 
        Troco, 
        Total, 
        MetodoDePagamento, 
        TelefoneMBWay, 
        Estado, 
        Data, 
        Hora,
        RequestInvoice,
        NIF,
        DocumentType,
        idUser,
        CustomerName,
        CustomerAddress,
        CustomerPostalCode,
        CustomerCity,
        CustomerCountry,
        CustomerVAT
    ) VALUES (
        '$newOrderNumber', 
        '$nomeCompleto', 
        '$turma', 
        '$permissao', 
        '$descricao',
        '$imagem', 
        '$valor',
        '$total',
        '$phone',
        '$metodoPagamento', 
        '0', 
        '$currentDate', 
        '$currentTime',
        '$requestInvoice',
        '$nif',
        '$documentType',
        '$idUser',
        '$customerName',
        '$customerAddress',
        '$customerPostalCode',
        '$customerCity',
        '$customerCountry',
        '$customerVAT'
    )";
    
    $result = $conn->query($sql);

    if ($result === TRUE) {
        // If insertion is successful, return success message with the new order number
        echo json_encode([
            'status' => 'success',
            'message' => 'Pedido adicionado com sucesso.',
            'orderNumber' => $newOrderNumber
        ]);
    } else {
        // If insertion fails, return error message
        echo json_encode([
            'status' => 'error',
            'message' => 'Erro ao adicionar o pedido: ' . $conn->error
        ]);
    }
} 