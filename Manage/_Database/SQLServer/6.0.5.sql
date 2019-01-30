/*
** Database Update package 6.0.5
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.5')
go
