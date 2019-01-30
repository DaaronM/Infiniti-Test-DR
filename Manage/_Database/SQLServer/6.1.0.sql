/*
** Database Update package 6.1.0
*/

--set version
truncate table dbversion
GO
insert into dbversion values ('6.1.0')
GO
