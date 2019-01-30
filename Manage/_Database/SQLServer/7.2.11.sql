/*
** Database Update package 7.2.11
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.2.11')
go
