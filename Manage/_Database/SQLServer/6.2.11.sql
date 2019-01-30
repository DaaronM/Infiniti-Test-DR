/*
** Database Update package 6.2.10
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.10')
go
