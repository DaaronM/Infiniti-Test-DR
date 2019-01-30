truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.3.0.3');
go
ALTER procedure [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@MessageXml xml = null,
	@UpdateRecent bit = 0
AS
	DECLARE @FinishDate datetime;
	DECLARE @UserGuid uniqueidentifier;
	DECLARE @TemplateGroupGuid uniqueidentifier;
	
	SET NOCOUNT ON;

	SET @FinishDate = GetUtcDate();
	SET @UserGuid = (SELECT User_Guid 
						FROM Template_Log
						INNER JOIN Intelledox_User ON Template_Log.[User_ID] = Intelledox_User.[User_ID]
						WHERE Log_Guid = @LogGuid);
	SET	@TemplateGroupGuid = (SELECT Template_Group_Guid 
								FROM Template_Log
								INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
								WHERE Log_Guid = @LogGuid);

	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Messages = @MessageXml,
			InProgress = 0
	WHERE	Log_Guid = @LogGuid;
	
	
	If @UpdateRecent = 1
	BEGIN
		--update recent completed log
		UPDATE	Template_Recent
		SET		Log_Guid = @LogGuid
		WHERE	User_Guid = @UserGuid 
				AND Template_Group_Guid = @TemplateGroupGuid;
	END
GO
DROP PROC spProject_GetProjectsByContentDefinition
GO
DROP PROC spContent_UpdateContentDefinitionItem
GO
DROP PROC spContent_RemoveContentDefinitionItems
GO
DROP PROC spContent_UpdateContentDefinition
GO
DROP PROC spContent_RemoveContentDefinition
GO
DROP PROC spContent_ContentItemListByDefinition
GO
DROP PROC spContent_ContentDefinitionList
GO
EXEC sp_rename 'dbo.Content_Definition', 'zzContent_Definition'
GO
EXEC sp_rename 'dbo.Content_Definition_Item', 'zzContent_Definition_Item'
GO
-- Added Phone number and Email address
ALTER VIEW [dbo].[vwUsersInGroups]
AS
SELECT      ug.Name as GroupName, ug.Group_Guid,
			u.UserName as Username, u.User_Guid, u.Business_unit_Guid,
			ab.Full_Name as FullName, ab.First_Name, ab.Last_Name, ab.Prefix,
			ab.Phone_Number, ab.Email_Address
FROM	    User_Group_Subscription ugs
LEFT JOIN	User_Group ug  ON ugs.GroupGuid = ug.Group_Guid
LEFT JOIN   Intelledox_User u ON ugs.UserGuid = u.User_Guid
LEFT JOIN	Address_Book ab on ab.Address_ID = u.Address_ID
GO
ALTER PROCEDURE [dbo].[spProject_DefinitionsByGroup] (
	@TemplateGroupGuid uniqueidentifier
)
AS
		SELECT	Template.Template_Guid, 
			Template.Template_Type_ID,
			Template.Template_Version, 
			Template.Project_Definition
		FROM	Template_Group
				INNER JOIN Template ON (Template_Group.Template_Guid = Template.Template_Guid 
						AND (Template_Group.Template_Version IS NULL
							OR Template_Group.Template_Version = Template.Template_Version))
					OR (Template_Group.Layout_Guid = Template.Template_Guid
						AND (Template_Group.Layout_Version IS NULL
							OR Template_Group.Layout_Version = Template.Template_Version))
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	UNION ALL
		SELECT	Template_Version.Template_Guid, 
			Template.Template_Type_ID,
			Template_Version.Template_Version, 
			Template_Version.Project_Definition
		FROM	Template_Group
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
				INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
						AND Template_Group.Template_Version = Template_Version.Template_Version)
					OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
						AND Template_Group.Layout_Version = Template_Version.Template_Version)
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	ORDER BY Template_Type_ID;
GO
ALTER PROCEDURE [dbo].[spProject_GetBinaries] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	File_Guid, FormatTypeId, [Binary]
		FROM	Template_File
		WHERE	Template_Guid = @TemplateGuid;
	END
	ELSE
	BEGIN
		SELECT	Template_File.File_Guid, Template_File.FormatTypeId, Template_File.[Binary]
		FROM	Template_File
				INNER JOIN Template ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @TemplateGuid
			AND Template.Template_Version = @VersionNumber
		UNION ALL
		SELECT	File_Guid, FormatTypeId, [Binary]
		FROM	Template_File_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber;
	END
GO
