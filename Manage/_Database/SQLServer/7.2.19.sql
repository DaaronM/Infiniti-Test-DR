/*
** Database Update package 7.2.19
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('7.2.19');
go
