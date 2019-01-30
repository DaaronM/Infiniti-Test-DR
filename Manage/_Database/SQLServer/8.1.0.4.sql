/*
** Database Update package 8.1.0.4
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.1.0.4');
go

--2054
INSERT INTO Group_Output(GroupGuid, FormatTypeId, LockOutput)
SELECT	DISTINCT GroupGuid, 12, 0
FROM	Group_Output
WHERE	GroupGuid NOT IN (
		SELECT	GroupGuid
		FROM	Group_Output
		WHERE	FormatTypeId = 12)
GO


