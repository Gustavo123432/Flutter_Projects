<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header('Content-Type: application/json');


// Database credentials
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "ToDo_ITG";
date_default_timezone_set("Europe/Lisbon");  

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}



//////////////////////////////////
///        1)   Login          ///
//////////////////////////////////
if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==1 && isset($_GET['pwd'])) 
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



/////////////////////////////////////
///  2)  Tar Por Começar por user ///
/////////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==2 && isset($_GET['id'])) 
{   
    $id=$_GET['id'];
    $sql = "SELECT * FROM tarefas WHERE DataIni IS NULL and CodUser=$id;";//dps trocar email para nome
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
///  3)  Tar Começada por user ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==3 && isset($_GET['id'])) 
{   
    $id=$_GET['id'];
    $sql = "SELECT * FROM tarefas WHERE DataIni IS NOT NULL and DateEnd IS NULL and CodUser=$id;";//dps trocar email para nome
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
/// 4) Tar Terminadas por user ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==4  && isset($_GET['id'])) 
{   
     $id=$_GET['id'];
    $sql = "SELECT * FROM tarefas WHERE DataIni IS NOT NULL and DateEnd IS NOT NULL and CodUser=$id;";//dps trocar email para nome
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
///     5)   Começar Tar       ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==5) 
{  
    $id=$_GET['id'];
    $date = date("y-m-d");
    $time = date("H:i:s");
    $sql = "UPDATE tarefas SET DataIni = '$date', TempIni = '$time' WHERE IdTarefa = $id;";//dps trocar email para nome
    $result = $conn->query($sql);
    echo TRUE; 
}



//////////////////////////////////
///     6)   Cancelar Tar      ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==6) 
{  
    $id=$_GET['id'];
    $sql = "UPDATE tarefas SET DataIni = null, TempIni = null WHERE IdTarefa = $id;";//dps trocar email para nome
    $result = $conn->query($sql);
    echo TRUE; 
}




//////////////////////////////////
///     7)   Terminar Tar      ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==7) 
{  
    $id=$_GET['id'];
    $det=$_GET['det'];
    $date = date("y-m-d");
    $time = date("H:i:s");
    $sql = "UPDATE tarefas SET DateEnd = '$date', TempEnd = '$time', Details='$det' WHERE IdTarefa = $id;";//dps trocar email para nome
    $result = $conn->query($sql);
    echo TRUE; 
}



//////////////////////////////////
///     8)   Criar Tar         ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==8 && isset($_GET['title']) && isset($_GET['descrip']) && isset($_GET['id']) && isset($_GET['prio'])) 
{  
    $prio=$_GET['prio'];
    //echo $prio;

    if($prio=='Prioritária')
    {
        $prio=1;
    }
    else  if($prio=='Urgente')
    {
        $prio=2;
        
    }
    else
    {$prio=0;}
    //echo $prio;
    $title=$_GET['title'];
    $descrip=$_GET['descrip'];
    $id=$_GET['id'];
    $sql = "insert into tarefas (Titulo, Descrip, CodUser, Priority) values ('$title', '$descrip', '$id', $prio);";//dps trocar email para nome
    $result = $conn->query($sql);
    echo TRUE; 
}



//////////////////////////////////
///   9)   Recolher Users      ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==9) 
{  
    $sql = "SELECT * FROM users;";//dps trocar email para nome
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



/////////////////////////////////////
///      10)  Tar Por Começar     ///
/////////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==10 && isset($_GET['order']))
{   
    $id=$_GET['id'];
    $type=$_GET['order'];
    $sql;
    if($type=='all')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NULL and t.CodUser=u.IdUser order by t.coduser;";
    }
    else if($type=='N Tarefa')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NULL and t.CodUser=u.IdUser order by t.idtarefa;";
    }
    else if($type=='Titulo')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NULL and t.CodUser=u.IdUser order by t.titulo;";
    }
    else if($type=='Prioridade')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NULL and t.CodUser=u.IdUser order by t.Priority desc;";
    }
    else if($type=='User')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NULL and t.CodUser=u.IdUser order by t.coduser;";
    }
    else if($type=='Minhas')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NULL and t.CodUser=u.IdUser and t.coduser=$id;";
    }
    else
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NULL and t.CodUser=u.IdUser order by t.coduser;";
    }

    //echo $type;
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



/////////////////////////////////////
///      11)  Tar Começadas       ///
/////////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==11 && isset($_GET['order'])) 
{   

   
    $id=$_GET['id'];
    $type=$_GET['order'];
    $sql;
    if($type=='all')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NOT NULL and DateEnd IS NULL and t.CodUser=u.IdUser order by t.coduser;";
    }
    else if($type=='N Tarefa')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NOT NULL and DateEnd IS NULL and t.CodUser=u.IdUser order by t.idtarefa;";
    }
    else if($type=='Titulo')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NOT NULL and DateEnd IS NULL and t.CodUser=u.IdUser order by t.titulo;";
    }
    else if($type=='Prioridade')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NOT NULL and DateEnd IS NULL and t.CodUser=u.IdUser order by t.Priority desc;";
    }
    else if($type=='User')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NOT NULL and DateEnd IS NULL and t.CodUser=u.IdUser order by t.coduser;";
    }
    else if($type=='Minhas')
    {
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NOT NULL and DateEnd IS NULL and t.CodUser=u.IdUser and t.coduser=$id;";
    }
    else
    { 
        $sql = "select t.*, u.name from tarefas t, users u WHERE t.DataIni IS NOT NULL and DateEnd IS NULL and t.CodUser=u.IdUser order by t.coduser;";
    }
    
    
    
    
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



/////////////////////////////////////
///    12)  Tar Finalizadas       ///
/////////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==12) 
{   

    $sql = "select t.*, u.name  from tarefas t, users u WHERE t.DataIni IS NOT NULL and DateEnd IS NOT NULL and t.CodUser=u.IdUser order by t.coduser;";//dps trocar email para nome
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
///  13) Recolher dados user   ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==13 && isset($_GET['id'])) 
{  

    $id=$_GET['id'];
    $sql = "select * from users where iduser=$id;";//dps trocar email para nome
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
///  14)  Alterar dados user   ///
//////////////////////////////////
else if ($_SERVER["REQUEST_METHOD"] === "GET" && $_GET['query_param']==14 && isset($_GET['nome']) && isset($_GET['cont']) && isset($_GET['pwd'])) 
{  

    $id=$_GET['id'];
    echo $id;
    $nome=$_GET['nome'];
    echo $nome;
    $contact=$_GET['cont'];
    echo $contact;
    $pwd=$_GET['pwd'];
    echo $pwd;
    $sql = "UPDATE users SET Name='$nome', Cont='$contact', pwd='$pwd' where iduser=$id";//dps trocar email para nome
    
    $result = $conn->query($sql);
    //echo TRUE; 
}


else 
{
    //echo "No data found for the query: $queryParam";
}



$conn->close();
?>