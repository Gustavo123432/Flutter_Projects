<?php

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header('Content-Type: application/json');

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$servername = "localhost:3306";
$username = "itg_dynado_admin";
$password = "1122#aabb";
$dbname = "itg_dynado";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
$conn->set_charset("utf8mb4");

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['query_param']) && $_POST['query_param'] == 1) {
        $log = $_POST['log'];
        $pwd = $_POST["pwd"];

        // Assuming you have a "salt" column in your 'users' table
        $sql = "SELECT salt FROM users WHERE log = '$log'";
        $result = $conn->query($sql);
		
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $salt = $row['salt'];
            $hash = crypt($pwd, '$2a$12$' . $salt);

            $sql = "SELECT iduser FROM users WHERE log = '$log' AND pwd = '$hash'";
            echo $sql;
			$result = $conn->query($sql);
			
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                echo json_encode($row);
				$id=$row['iduser'];

				$rawSalt = random_bytes(20); 
				$formattedSalt = bin2hex($rawSalt);
				$pass=crypt($pwd, '$2a$12$'.$formattedSalt);

				$sql="update users set pwd='$pass', salt='$formattedSalt' where iduser=$id";
				$result=$conn->query($sql);

            } else {
                echo json_encode("False");
            }
        } else {
            echo json_encode("Error, parameters not right");
        }
    }
}

$conn->close();
?>
