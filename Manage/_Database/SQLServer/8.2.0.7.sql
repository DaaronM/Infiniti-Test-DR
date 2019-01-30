/*
** Database Update package 8.2.0.7
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.0.7');
go

--2112
CREATE procedure [dbo].[spGroups_IdToGuid]
	@id int
AS
	SELECT	Group_Guid
	FROM	User_Group
	WHERE	User_Group_ID = @id;
GO

--2113
UPDATE	permission
SET		Name = 'Management console'
WHERE	Name = 'Management Console';

UPDATE	permission
SET		Name = 'Manage workflow tasks'
WHERE	Name = 'Manage Workflow Tasks';

UPDATE	permission
SET		Name = 'Change settings'
WHERE	Name = 'Change Settings';

UPDATE	permission
SET		Name = 'Content approver'
WHERE	Name = 'Content Approver';

UPDATE	permission
SET		Name = 'Manage content library'
WHERE	Name = 'Manage Content Library';
GO


