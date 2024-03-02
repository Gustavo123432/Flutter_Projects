document.addEventListener('DOMContentLoaded', function() {
    // Exibe o status com base na informação do PHP
    const statusElement = document.getElementById('status');
    if (conexaoBemSucedida) {
        
      statusElement.textContent = 'ON';
      statusElement.classList.add('success');
    } else {
      statusElement.textContent = 'OFF';
      statusElement.classList.add('error');
    }
  });
  