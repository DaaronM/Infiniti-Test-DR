/*
** Database Update package 6.3.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.3.3')
go
