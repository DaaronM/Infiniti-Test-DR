/*
** Database Update package 8.2.0.8
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.0.8');
go
