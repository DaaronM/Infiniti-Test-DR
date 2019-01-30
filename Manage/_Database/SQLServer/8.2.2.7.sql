/*
** Database Update package 8.2.2.7
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.2.7');
go

INSERT INTO Global_Options (OptionCode, OptionDescription, OptionValue)
VALUES ('KEEP_WORKFLOW_HISTORY', 'Keep Workflow History', 'false');
GO
