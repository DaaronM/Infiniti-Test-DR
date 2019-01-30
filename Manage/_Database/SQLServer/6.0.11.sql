/*
** Database Update package 6.0.11
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.11')
go

