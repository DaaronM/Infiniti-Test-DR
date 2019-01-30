/*
** Database Update package 7.1.14
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.14')
go
