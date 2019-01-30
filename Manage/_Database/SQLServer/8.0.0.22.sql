/*
** Database Update package 8.0.0.22
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0.22');
go
