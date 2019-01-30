/*
** Database Update package 7.1.10
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.10')
go
