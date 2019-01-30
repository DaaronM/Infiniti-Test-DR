/*
** Database Update package 6.2.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.1')
go
