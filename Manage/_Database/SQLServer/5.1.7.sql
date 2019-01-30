/*
** Database Update package 5.1.7
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.7')
go

--1852
DROP PROCEDURE dbo.spProjectGp_IdToGuid
GO
CREATE PROCEDURE dbo.spProjectGrp_IdToGuid
	@id int
AS
	SELECT	Template_Group_Guid
	FROM	Template_Group
	WHERE	Template_Group_Id = @id;
GO

