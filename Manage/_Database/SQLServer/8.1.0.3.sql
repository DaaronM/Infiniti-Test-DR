/*
** Database Update package 8.1.0.3
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.1.0.3');
go

--2053
ALTER TABLE ActionListState
	ADD IsComplete bit not null default (0)
GO
UPDATE	ActionListState
SET		IsComplete = 1
WHERE	AnswerFileXml IS NOT NULL
GO

