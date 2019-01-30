/*
** Database Update package 6.1.7
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.7')
go
