/*
** Database Update package 7.0.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.2')
go
