-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Tempo de geração: 21-Abr-2025 às 15:08
-- Versão do servidor: 10.11.11-MariaDB-0ubuntu0.24.04.2
-- versão do PHP: 8.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `sibs_mbway`
--

-- --------------------------------------------------------

--
-- Estrutura da tabela `sibs_mandates`
--

CREATE TABLE `sibs_mandates` (
  `id` int(11) NOT NULL,
  `mandate_id` varchar(64) NOT NULL,
  `client_name` varchar(45) DEFAULT NULL,
  `alias` varchar(256) DEFAULT NULL,
  `type` varchar(10) DEFAULT NULL COMMENT 'ONECLICK or SUBSCRIPTION',
  `status` varchar(10) DEFAULT NULL COMMENT 'ACTV, SSPN, EXPR, CNCL',
  `amount_limit` decimal(10,2) DEFAULT NULL,
  `expiration_date` date DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `sibs_notifications`
--

CREATE TABLE `sibs_notifications` (
  `id` int(11) NOT NULL,
  `notification_id` varchar(36) NOT NULL,
  `transaction_id` varchar(35) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `processed_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `transactions`
--

CREATE TABLE `transactions` (
  `id` int(11) NOT NULL,
  `transaction_id` varchar(35) NOT NULL,
  `transaction_signature` text DEFAULT NULL,
  `merchant_id` varchar(50) DEFAULT NULL,
  `terminal_id` int(11) DEFAULT NULL,
  `payment_method` varchar(20) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `currency` varchar(3) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tabelas despejadas
--

--
-- Índices para tabela `sibs_mandates`
--
ALTER TABLE `sibs_mandates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `mandate_id` (`mandate_id`);

--
-- Índices para tabela `sibs_notifications`
--
ALTER TABLE `sibs_notifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `notification_id` (`notification_id`);

--
-- Índices para tabela `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `transaction_id` (`transaction_id`);

--
-- AUTO_INCREMENT de tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `sibs_mandates`
--
ALTER TABLE `sibs_mandates`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `sibs_notifications`
--
ALTER TABLE `sibs_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

