/*
** Database Update package 7.0.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.3')
go
