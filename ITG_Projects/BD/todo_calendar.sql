DROP DATABASE IF EXISTS ToDo_Calendar;
CREATE DATABASE ToDo_Calendar DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;SET NAMES utf8;
SET character_set_connection=utf8;SET character_set_client=utf8;
SET character_set_results=utf8;

Use ToDo_Calendar;



create table Users (
IdUser INT(10) PRIMARY KEY auto_increment,
Name VARCHAR(75),
Pwd VARCHAR(10) Binary,
Log Varchar(10),
Cont VARCHAR(75),
Mail VARCHAR(75),
Type Int(10),
Image BLOB
);
    
create table Tarefas (
IdTarefa INT(10) PRIMARY KEY auto_increment,
Titulo VARCHAR(45),
Descrip VARCHAR(75),
DataIni DATE,
TempIni TIME,
DateEnd DATE,
TempEnd TIME,
CodUser Int(10),
FOREIGN KEY (CodUser) REFERENCES Users(IdUser),
Reopen VARCHAR(75),
Details VARCHAR(75),
Priority INT(10)
);

create table tickets(
IdTicket INT(10) PRIMARY KEY auto_increment,
Titulo VARCHAR(45),
Descricao VARCHAR(75),
Prioridade INT(10),
Estado INT(10)
);

insert into users values(1, 'Guilherme Silveira', '123', 'gui', '+351 914 012 970', 'guilherme.silveira@interagit.com', 1, null);
insert into users values(2, 'Rafael Pedrosa', '123', 'rafa', '+351 925 392 389', 'rafael.pedrosa@interagit.com', 1, null);
insert into users values(3, 'António Barbosa', '123', 'toni', '+351 916 299 412', 'antonio.barbosa@interagit.com', 0, null);

insert into tarefas(Titulo, Descrip, DataIni, TempIni, DateEnd, TempEnd, Color) values ('Teste1', 'Descriçãao', '2023-11-06', '12:27:00', '2023-11-07', '12:30:01', 'deadf1');