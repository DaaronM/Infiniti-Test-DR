/*
** Database Update package 5.1.1.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.1.1')
go
