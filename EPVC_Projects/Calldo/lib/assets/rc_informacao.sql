-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Feb 16, 2024 at 11:13 AM
-- Server version: 10.5.20-MariaDB
-- PHP Version: 8.2.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `itg_calldo`
--

-- --------------------------------------------------------

--
-- Table structure for table `rc_informacao`
--

CREATE TABLE `rc_informacao` (
  `ID` int(11) NOT NULL,
  `Perfil` varchar(250) NOT NULL,
  `Local` varchar(250) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rc_informacao`
--

INSERT INTO `rc_informacao` (`ID`, `Perfil`, `Local`) VALUES
(1, 'Gestor Projetos', 'Remoto'),
(2, 'Consultor Estratégico', 'Cliente'),
(3, 'Consultor IT&SI', 'Teletrabalho'),
(4, 'Administrador IT&SI', 'XRS CPP'),
(5, 'Administrador Segurança', 'XRS CPB'),
(6, 'Administrador Redes', 'XRS CPA'),
(7, 'Administrador Comunicações', 'XRS EP Porto'),
(8, 'Administrador Sistemas', 'XRS EP Braga'),
(9, 'HelpDesk 1ª Linha', 'XRS BP'),
(10, 'HelpDesk 2ª Linha', 'XRS BB'),
(11, 'Formador', ''),
(12, 'Eletricista', '');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `rc_informacao`
--
ALTER TABLE `rc_informacao`
  ADD PRIMARY KEY (`ID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `rc_informacao`
--
ALTER TABLE `rc_informacao`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
