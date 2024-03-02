DROP DATABASE IF EXISTS ToDo_ITG;
CREATE DATABASE ToDO_ITG DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;SET NAMES utf8;
SET character_set_connection=utf8;SET character_set_client=utf8;
SET character_set_results=utf8;USE ToDo_ITG;

Use ToDo_ITG;



create table Users (
IdUser INT(10) PRIMARY KEY,
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

insert into users values(1, 'Guilherme Silveira', '123', 'gui', '+351 914 012 970', 'guilherme.silveira@interagit.com', 1, null);
insert into users values(2, 'Rafael Pedrosa', '123', 'rafa', '+351 925 392 389', 'rafael.pedrosa@interagit.com', 1, null);
insert into users values(3, 'António Barbosa', '123', 'toni', '+351 916 299 412', 'antonio.barbosa@interagit.com', 0, null);