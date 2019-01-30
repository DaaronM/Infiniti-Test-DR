/*
** Database Update package 6.3.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.3.2')
go
