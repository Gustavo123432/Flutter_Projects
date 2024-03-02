<?php
	
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header('Content-Type: application/json');


// Database configuration
$servername = "localhost:3306";
$username = "itg_doodo_admin";
$password = "1122#aabb";
$dbname = "itg_doodo";


// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
$conn->set_charset("utf8mb4");
//echo "<p>$conn->connect_error</p>";


// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==0)
{
	error_reporting(E_ALL);
ini_set('display_errors', 1);

}

//// Aqui começa os Requests dos Users 1-10 ////

//////////////////////////////////
///  1) Login				   ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==1 && isset($_GET['pwd']) && isset($_GET['name']))
{   
    $name= $_GET['name'];
    $pwd= $_GET['pwd'];
    $sql = "SELECT iduser, type FROM Users WHERE log = '$name' and BINARY pwd='$pwd';";
    $result = $conn->query($sql);
    $list=array();
    $data = array();
    if ($result->num_rows > 0) 
    {
        while ($row = $result->fetch_assoc()) 
        {
            $list[]=$row;
            echo json_encode($list);
        }
    }
    else
    {
        $list='false';
        echo json_encode($list);
       
    }
        
        
}

//////////////////////////////////
///  2) Recolher dados user   ////
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==2 && isset($_GET['id'])) 
{  

    $id=$_GET['id'];
    $sql = "select name, mail from users where iduser=$id;";//dps trocar email para nome
    $result = $conn->query($sql);
    $list=array();
    $data = array();
    if ($result->num_rows > 0) 
    {
        while ($row = $result->fetch_assoc()) 
        {
            $list[]=$row;
        }
       
    }
    else
    {
        $data=false;
    }
        echo json_encode($list);
}


//////////////////////////////////
///  3) Imagens                ///
//////////////////////////////////

else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==3 && isset($_GET['imageName'])) 
{   
    $imageName = $_GET['imageName'];
    $imageDirectory = "C:/Inetpub/vhosts/interagit.com/services.interagit.com/App_Data/TesteImagens/";
    // Construct the full path to the image
    $imagePath = $imageDirectory . $imageName;
	
	//echo $imagePath;
	
	  // Check if the file exists
    if (file_exists($imagePath)) {
		 // Read the content of the image file
        $imageContent = file_get_contents($imagePath);
		//echo $imageContent;
        // Encode the image content as base64
        $imageBase64 = base64_encode($imageContent);
		//echo $imageBase64;
		$response=['imageName' => $imageName, 'imageData' => $imageBase64];
       

        echo json_encode($response);
        exit;
       
    } else {
        echo "Image not found.";
    }
        
}

//////////////////////////////////
///  4) Todos Users            ///
//////////////////////////////////

else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==4) 
{  
    $sql = "select * from users";
    $result = $conn->query($sql);
    $list=array();
    $data = array();
    if ($result->num_rows > 0) 
    {
        while ($row = $result->fetch_assoc()) 
        {
            $list[]=$row;
        }
       
    }
    else
    {
        $data=false;
    }
        echo json_encode($list);
}


//////////////////////////////////
///  5) Criar Users            ///
//////////////////////////////////

else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==5 && isset($_GET['name']) && isset($_GET['pwd']) && isset($_GET['log']) && isset($_GET['cont']) && isset($_GET['mail']) && isset($_GET['type']) && isset($_GET['color']))
{  
    $type=$_GET['type'];
    $name=$_GET['name'];
    $pwd=$_GET['pwd'];
    $log=$_GET['log'];
    $mail=$_GET['mail'];
    $cont=$_GET['cont'];
	$color=$_GET['color'];
    $sql = "insert into users (Name, Pwd, Log, Mail, Cont, Type, Color) values ('$name', '$pwd', '$log', '$mail', '$cont', $type, '$color');";//dps trocar email para nome
    $result = $conn->query($sql);
	$conn->close();
	
	$conn = new mysqli($servername, $username, $password, $dbname);
	$conn->set_charset("utf8mb4");
	
	$sql = "select iduser from users where Log='$log' and Pwd='$pwd';";
    $result = $conn->query($sql);
    $list=array();
    $data = array();
    if ($result->num_rows > 0) 
    {
        while ($row = $result->fetch_assoc()) 
        {
            $list[]=$row;
        }
       
    }
    else
    {
        $data=false;
    }
        echo json_encode($list);
	
    //echo TRUE; 
}


//////////////////////////////////
///  6) Mod Users              ///
//////////////////////////////////

else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==6 && isset($_GET['Name']) && isset($_GET['Cont']) && isset($_GET['Pwd'])) 
{  

    $id=$_GET['id'];
    echo $id;
    $nome=$_GET['Name'];
    echo $nome;
    $contact=$_GET['Cont'];
    echo $contact;
    $pwd=$_GET['Pwd'];
    echo $pwd;
    $sql = "UPDATE users SET Name='$nome', Cont='$contact', Pwd='$pwd' where iduser=$id";//dps trocar email para nome

    $result = $conn->query($sql);
    //echo TRUE; 
}

//////////////////////////////////
///  7) Delete Users           ///
//////////////////////////////////

//////////////////////////////////
///  8)   Images Todas         ///
//////////////////////////////////

if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param'] == 8) {
    $imageDirectory = "C:/Inetpub/vhosts/interagit.com/services.interagit.com/App_Data/TesteImagens/";

    $userImages = [];

    // Open the directory
    if ($handle = opendir($imageDirectory)) {
        // Loop through each file in the directory
        while (false !== ($entry = readdir($handle))) {
            if ($entry != "." && $entry != "..") {
                $imagePath = $imageDirectory . $entry;

                // Read the content of the image file
                $imageContent = file_get_contents($imagePath);

                // Encode the image content as base64
                $imageBase64 = base64_encode($imageContent);

                // Add image data to the array
                $userImages[] = ['imageName' => $entry, 'imageData' => $imageBase64];
            }
        }

        // Close the directory handle
        closedir($handle);

        // Send JSON response with all user images
        echo json_encode($userImages);
    } else {
        // Send a JSON response if there's an issue opening the directory
        echo json_encode(['error' => 'Unable to open image directory.']);
    }
}


//////////////////////////////////
///  9)  			           ///
//////////////////////////////////

else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==9 && isset($_GET['id'])) 
{  
	$id=$_GET['id'];
    $sql = "select * from users where iduser=$id;";
    $result = $conn->query($sql);
    $list=array();
    $data = array();
    if ($result->num_rows > 0) 
    {
        while ($row = $result->fetch_assoc()) 
        {
            $list[]=$row;
        }
       
    }
    else
    {
        $data=false;
    }
        echo json_encode($list);
}

//////////////////////////////////
///  10) 				       ///
//////////////////////////////////




//// Aqui começa os Requests das Tarefas 11-20 ////


//////////////////////////////////
///  11) Recolher todas Tar    ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==11 ) 
{  
    $sql = "select t.titulo, t.Descrip, t.DataM, t.TempM, t.DateEnd, t.TempEnd, t.CodUser, u.color from tarefas t, users u where t.CodUser=u.iduser;";
    $result = $conn->query($sql);
    $list=array();
    $data = array();
    if ($result->num_rows > 0) 
    {
        while ($row = $result->fetch_assoc()) 
        {
            $list[]=$row;
        }
       
    }
    else
    {
        $data=false;
    }
        echo json_encode($list);
	
        
	
}

////////////////////////////////////
///  12) Recolher  Tar  User OP2 ///
////////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==12 && isset($_GET['id'])) 
{   
    $id=$_GET['id'];
    $sql = "SELECT idtarefa, titulo, descrip, namecliente, datam, tempm, loci, locf from tarefas WHERE CodUser=$id and state=0";//dps trocar email para nome
    $result = $conn->query($sql);
    $list=array();
    $data = array();
    if ($result->num_rows > 0) 
    {
        while ($row = $result->fetch_assoc()) 
        {
            $list[]=$row;
        }
    }
    else
    {
        $data=false;
    }
        echo json_encode($list);
       // return $data;
}    


//////////////////////////////////
///  13)               	       ///
//////////////////////////////////

//////////////////////////////////
///  14)               	       ///
//////////////////////////////////

//////////////////////////////////
///  15) Inserir tarefas       ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==15 && isset($_GET["Titulo"]) && isset($_GET["Descrip"]) && isset($_GET["DataIni"]) && isset($_GET["TempIni"]) && isset($_GET["TempEnd"]) && isset($_GET["DateEnd"]) && $_GET["Color"] && isset($_GET["id"])) 
{
    $title=$_GET["Titulo"];
    $descrip=$_GET["Descrip"];
    $dataini=$_GET["DataIni"];
    $dateend=$_GET["DateEnd"];
    $tempini=$_GET["TempIni"];
    $tempend=$_GET["TempEnd"];
    $color=$_GET["Color"];
	$id=$_GET["id"];
    $sql="insert into tarefas(Titulo, Descrip, DataIni, TempIni, DateEnd, TempEnd, Color, CodUser) values ('$title', '$descrip', '$dataini', '$tempini', '$dateend', '$tempend', '$selectedColor', '$id');";
    $result = $conn->query($sql);

}

//////////////////////////////////
///  16) Começar Tar           ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==16 && isset($_GET['id'])) 
{   
    $id=$_GET['id'];
    $sql = "SELECT idtarefa, titulo, descrip, namecliente, datam, tempm, loci, locf from tarefas WHERE CodUser=$id and state=0";//dps trocar email para nome
    $result = $conn->query($sql);
    $list=array();
    $data = array();
    if ($result->num_rows > 0) 
    {
        while ($row = $result->fetch_assoc()) 
        {
            $list[]=$row;
        }
    }
    else
    {
        $data=false;
    }
        echo json_encode($list);
       // return $data;
}  
//////////////////////////////////
///  17) Delete tarefas        ///
//////////////////////////////////


//////////////////////////////////
///  18) 		               ///
//////////////////////////////////


//////////////////////////////////
///  19) 			           ///
//////////////////////////////////


//////////////////////////////////
///  20)     			       ///
//////////////////////////////////



$conn->close();

?>



