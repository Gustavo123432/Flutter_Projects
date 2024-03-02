DROP DATABASE IF EXISTS itg_calldo;
CREATE DATABASE itg_calldo DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;SET NAMES utf8;
SET character_set_connection=utf8;SET character_set_client=utf8;
SET character_set_results=utf8;

Use itg_calldo;


create table rc_local
(
    IdLocal int(10) PRIMARY KEY auto_increment,
    Local Varchar(75)
);

create table rc_ccp
(
    IdCCP int(10) PRIMARY KEY auto_increment,
    CCP Varchar(250)
);



create table rc_perfil
(
    IdPerfil int(10) PRIMARY KEY auto_increment,
    Perfil Varchar(75)
);



create table rc_users
(
    IdUser int(10) PRIMARY KEY auto_increment,
    Nome Varchar(75),
    Apelido Varchar(75),
    User Varchar(75),
    Password Varchar(75),
    Permissao Varchar(75),
    Imagem mediumtext
);



create table rc_registo
(
    IdRegisto int(10) PRIMARY KEY auto_increment,
    Descricao Varchar(75),
    Tecnico int(10),
    FOREIGN KEY (Tecnico) REFERENCES rc_users(IdUser),
    Data DATE,
    Hora_Inicio TIME,
    Hora_Fim TIME,
    Horas TIME,
    Perfil int(10),
    FOREIGN KEY (Perfil) REFERENCES rc_perfil(IdPerfil),
    Local int(10),
    FOREIGN KEY (Local) REFERENCES rc_local(IdLocal),
    Centro_Custo_Projeto int(10)
    FOREIGN KEY (CCP) REFERENCES rc_ccp(IdCCP),
);








INSERT INTO rc_local VALUES
(1, 'Remoto'),
(2, 'Cliente'),
(3, 'Teletrabalho'),

(4, 'XRS BB'),
(5, 'XRS BP'),
(6, 'XRS CPA'),
(7, 'XRS CPB'),
(8, 'XRS CPP'),
(9, 'XRS EP Braga'),
(10, 'XRS EP Porto');


INSERT INTO rc_ccp VALUES
(1, 'XRS Avença Suporte'),
(2, 'XRS Projecto CPA New Office 2020'),
(3, 'XRS Projecto EP Porto New Office 2023'),
(4, 'XRS Projecto BP New Office 2021'),
(5, 'XRS Projeto CPB New Office 2024'),
(6, 'Taxis RF Serviço');


INSERT INTO rc_perfil VALUES
(1, 'Gestor Projetos'),
(2, 'Consultor Estratégico'),
(3, 'Consultor IT&SI'),
(4, 'Administrador IT&SI'),
(5, 'Administrador Segurança'),
(6, 'Administrador Redes'),
(7, 'Administrador Comunicações'),
(8, 'Administrador Sistemas'),
(9, 'HelpDesk 1ª Linha'),
(10, 'HelpDesk 2ª Linha'),
(11, 'Formador'),
(12, 'Eletricista'),
(12, 'DevOps'),
(12, 'Programador');

insert into rc_users VALUES
(1, 'Adm', 'Adm', 'adm', 'e10adc3949ba59abbe56e057f20f883e', 'Administrador', 'asdasd');