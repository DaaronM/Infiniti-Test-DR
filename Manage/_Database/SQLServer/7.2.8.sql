/*
** Database Update package 7.2.8
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('7.2.8');
go
