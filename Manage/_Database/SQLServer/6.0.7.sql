/*
** Database Update package 6.0.7
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.7')
go
