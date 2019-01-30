/*
** Database Update package 7.1.12
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.12')
go
