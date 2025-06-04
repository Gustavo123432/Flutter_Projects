-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Tempo de geração: 08-Mar-2025 às 22:58
-- Versão do servidor: 8.0.41-0ubuntu0.24.04.1
-- versão do PHP: 8.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `appbar_monte`
--

-- --------------------------------------------------------

--
-- Estrutura da tabela `ab_comidas`
--

CREATE TABLE `ab_comidas` (
  `id` int NOT NULL,
  `nome` varchar(250) NOT NULL,
  `ingredientes` text NOT NULL,
  `preco` double NOT NULL,
  `imagem` longtext NOT NULL,
  `estado` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Extraindo dados da tabela `ab_comidas`
--

INSERT INTO `ab_comidas` (`id`, `nome`, `ingredientes`, `preco`, `imagem`, `estado`) VALUES
(3, 'fdsfsdfsdfd', 'fdsfsdf', 6, '', 0);

-- --------------------------------------------------------

--
-- Estrutura da tabela `ab_reservas`
--

CREATE TABLE `ab_reservas` (
  `id` int NOT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `numeroPessoas` int NOT NULL,
  `name` text NOT NULL,
  `description` text NOT NULL,
  `createdAt` datetime NOT NULL,
  `aluno` varchar(250) NOT NULL,
  `estado` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Extraindo dados da tabela `ab_reservas`
--

INSERT INTO `ab_reservas` (`id`, `date`, `time`, `numeroPessoas`, `name`, `description`, `createdAt`, `aluno`, `estado`) VALUES
(1, '2025-01-14', '22:22:00', 2, 'fefwefwef', 'Panados', '2025-01-14 22:18:20', '220402', 1),
(2, '2025-01-15', '12:40:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-01-15 21:22:46', 'null', 0),
(4, '2025-01-15', '12:50:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-01-15 21:35:12', '220412@epvc.pt', 0),
(5, '2025-01-17', '12:50:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-01-15 21:41:24', '220412@epvc.pt', 0),
(6, '2025-01-17', '12:50:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-01-15 21:41:34', '220412@epvc.pt', 0),
(7, '2025-01-16', '12:40:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-01-15 21:42:29', '220412@epvc.pt', 0),
(8, '2025-01-16', '12:50:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-01-15 21:43:18', '220412@epvc.pt', 0),
(9, '2025-01-21', '13:00:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-01-21 09:44:43', '220412@epvc.pt', 0),
(10, '2025-02-11', '12:50:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-02-10 21:43:13', '220412@epvc.pt', 0),
(11, '2025-02-19', '12:30:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-02-18 15:32:36', '220412@epvc.pt', 0),
(12, '2025-03-05', '11:50:00', 1, 'Gustavo Ferreira Araújo', 'Tset', '2025-03-05 18:25:11', '220412@epvc.pt', 1),
(13, '2025-03-07', '12:50:00', 1, 'Gustavo Ferreira Araújo', 'test', '2025-01-15 21:41:24', '220412@epvc.pt', 0);

--
-- Índices para tabelas despejadas
--

--
-- Índices para tabela `ab_comidas`
--
ALTER TABLE `ab_comidas`
  ADD PRIMARY KEY (`id`);

--
-- Índices para tabela `ab_reservas`
--
ALTER TABLE `ab_reservas`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `ab_comidas`
--
ALTER TABLE `ab_comidas`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `ab_reservas`
--
ALTER TABLE `ab_reservas`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
