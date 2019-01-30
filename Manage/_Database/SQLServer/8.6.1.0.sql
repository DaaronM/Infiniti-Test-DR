truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.1.0');
go

ALTER TABLE ActionListState
	ADD AllowCancellation bit not null default (0)
GO
