/*
** Database Update package 6.2.8
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.8')
go
