CREATE TABLE pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL,
    payment_id VARCHAR(100),
    status ENUM('pending', 'paid', 'cancelled') DEFAULT 'pending',
    total DECIMAL(10,2) NOT NULL,
    payment_method ENUM('dinheiro', 'mbway') NOT NULL,
    phone_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
); 