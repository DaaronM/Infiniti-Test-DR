/*
** Database Update package 7.1.19
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.19')
go
