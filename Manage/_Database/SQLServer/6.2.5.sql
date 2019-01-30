/*
** Database Update package 6.2.5
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.5')
go
