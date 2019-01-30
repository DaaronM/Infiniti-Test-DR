/*
** Database Update package 8.2.1
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.1');
go

--2115
ALTER TABLE ActionListState
ADD IsAborted [bit] NOT NULL DEFAULT ((0))
GO

