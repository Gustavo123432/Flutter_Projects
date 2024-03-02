<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Seu Site</title>
  <style>
    #loader {
      border: 8px solid #f3f3f3;
      border-top: 8px solid #3498db;
      border-radius: 50%;
      width: 50px;
      height: 50px;
      animation: spin 1s linear infinite;
      position: fixed;
      top: 50%;
      left: 50%;
      margin-top: -25px;
      margin-left: -25px;
      display: none; /* Esconde por padrão */
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>

<div id="loader"></div>

<script>
  // Mostra a barra de progresso
  document.getElementById('loader').style.display = 'block';

  // Espera 5 segundos antes de redirecionar para o arquivo.php
  setTimeout(function() {
    // Substitua "arquivo.php" pelo nome do seu arquivo PHP
    window.location.href = 'paginaDasPiadas.php';
  }, 5000);
</script>

<!-- O restante do seu conteúdo vai aqui -->

</body>
</html>
