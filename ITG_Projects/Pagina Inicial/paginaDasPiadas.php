<!DOCTYPE html>
<html lang="pt">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <link rel="stylesheet" href="styles/style.css">
    <script src="javascript/script.js"></script>
    <title>Status</title>
</head>

<body>
    <a href="https://interagit.com" target="_blank">
        <img src="logo.png" alt="Logo" class="logo">
    </a>
    <div class="card">
        <?php
        header('Content-Type: text/html; charset=UTF-8');
        
        //Verificação conexão
        $servername = "localhost:3306";
        $username = "root";
        $password = "";
        $dbname = "pagina_inicial";
        $conn = new mysqli($servername, $username, $password, $dbname);
        $conn->set_charset("utf8mb4");

        if ($conn->connect_error) {
            $conexaoBemSucedida = false; 
        } 
        else {
            $conexaoBemSucedida = true;
        }

        //Randoms
        $randomNumber = rand(3, 22);
        $cofe1 = rand(2, 15);

        //IF
        if ($randomNumber > 26) {
            $randomNumber = 1;
        }

        $sql = "SELECT piada FROM itg_doodo WHERE idteste = $randomNumber";
        $result = $conn->query($sql);

        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $piada = $row['piada'];
        }

        //Mostrar ecrã
        //ligado no javascript
        echo "<span>Status Base de Dados: </span>";
        echo "<span id='status'> </span> ";

        echo "<p>Detalhes da Conexão MySQLi:\n</p>";
        echo "<p>Versão do Protocolo: " . $conn->protocol_version . "</p>";
        echo "<p>Versão do Servidor: " . $conn->server_info . "</p>";

        echo "<br>";
        echo "<p class='p2'>Cafés Tomados:". $cofe1 ."</p>";

        echo "<h3>$piada</h3>";

        $conn->close();
        ?>
        <script>
            const conexaoBemSucedida = <?php echo json_encode($conexaoBemSucedida); ?>;
        </script>
    </div>
</body>

</html>