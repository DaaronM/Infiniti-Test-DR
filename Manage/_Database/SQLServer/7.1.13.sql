/*
** Database Update package 7.1.13
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.13')
go
