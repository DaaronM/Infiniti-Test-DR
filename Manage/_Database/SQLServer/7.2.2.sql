/*
** Database Update package 7.2.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.2.2')
go
