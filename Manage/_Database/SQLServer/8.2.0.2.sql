/*
** Database Update package 8.2.0.2
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.0.2');
go

--2082
ALTER VIEW [dbo].[vwTemplateVersion]
AS
	SELECT	Template_Version.Template_Version, 
			Template_Version.Template_Guid,
			Template_Version.Modified_Date,
			Template_Version.Comment,
			Template.Template_Type_ID,
			Template.LockedByUserGuid,
			Intelledox_User.Username,
			CASE (SELECT COUNT(*)
					FROM Template_Group 
					WHERE (Template_Group.Template_Guid = Template_Version.Template_Guid
								AND Template_Group.Template_Version = Template_Version.Template_Version)
							OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
								AND Template_Group.Layout_Version = Template_Version.Template_Version)) 
				WHEN 0
				THEN 0
				ELSE 1
			END AS InUse,
			0 AS Latest
		FROM	Template_Version
			INNER JOIN Template ON Template_Version.Template_Guid = Template.Template_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template_Version.Modified_By
	UNION ALL
		SELECT	Template.Template_Version, 
				Template.Template_Guid,
				Template.Modified_Date,
				Template.Comment,
				Template.Template_Type_ID,
				Template.LockedByUserGuid,
				Intelledox_User.Username,
				CASE (SELECT COUNT(*)
						FROM Template_Group 
						WHERE (Template_Group.Template_Guid = Template.Template_Guid
									AND (Template_Group.Template_Version = Template.Template_Version OR ISNULL(Template_Group.Template_Version, 0) = 0))
							OR (Template_Group.Layout_Guid = Template.Template_Guid
									AND (Template_Group.Layout_Version = Template.Template_Version OR ISNULL(Template_Group.Layout_Version, 0) = 0)))
					WHEN 0
					THEN 0
					ELSE 1
				END AS InUse,
				1 AS Latest
		FROM	Template
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By;
GO


--2083
ALTER PROCEDURE [dbo].[spProject_TryLockProject]
	@ProjectGuid uniqueidentifier,
	@UserGuid uniqueidentifier
	
AS

	BEGIN TRAN
	
		--check for a deleted project
		IF NOT EXISTS(SELECT 1 FROM Template WHERE Template_Guid = @ProjectGuid) 
			SELECT ''
		ELSE
		BEGIN
			IF EXISTS(SELECT 1 FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid IS NULL)
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = @UserGuid
				WHERE	Template_Guid = @ProjectGuid;
				
				SELECT ''				
			END
			ELSE
			BEGIN
				SELECT	Username 
				FROM	Intelledox_User 
						INNER JOIN Template ON Intelledox_User.User_Guid = Template.LockedByUserGuid
				WHERE	Template_Guid = @ProjectGuid						
			END
		END
		
	COMMIT
	
GO

--2084
ALTER PROCEDURE [dbo].[spProject_UnlockProject]
	@ProjectGuid uniqueidentifier,
	@VersionComment text = '',
	@UserGuid uniqueidentifier,
	@ForceUnlock bit
AS

	BEGIN TRAN
	
		--allows unlock either by any user if its a force unlock OR by the same user who has currently locked the project if general unlock
		IF @ForceUnlock = 1 OR (@ForceUnlock = 0 AND EXISTS(SELECT LockedByUserGuid FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid = @UserGuid))
		BEGIN
			IF EXISTS(SELECT Comment FROM Template WHERE Template_Guid = @ProjectGuid AND LEN(Comment) > 0) AND DATALENGTH(@VersionComment) = 0
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = NULL
				WHERE	Template_Guid = @ProjectGuid;
			END
			ELSE
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = NULL,
						Comment = @VersionComment
				WHERE	Template_Guid = @ProjectGuid;
			END
		END

	COMMIT
	
GO

--2085
ALTER procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@ProjectTypeID int,
	@SupplierGuid uniqueidentifier,
	@ContentBookmark nvarchar(100),
	@IsMajorVersion bit = 0,
	@UserGuid uniqueidentifier = NULL
as
	DECLARE @FloatVersion float
	DECLARE @StrVersion nvarchar(10)

	BEGIN TRAN

		IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
		BEGIN
			INSERT INTO Template(Business_Unit_Guid, Name, Template_Guid, 
				Template_Type_Id, Supplier_Guid, Content_Bookmark, Template_Version)
			VALUES (@BusinessUnitGuid, @Name, @ProjectGuid, 
				@ProjectTypeId, @SupplierGuid, @ContentBookmark, 0);
		END
		ELSE
		BEGIN
		
			IF @UserGuid IS NOT NULL
			BEGIN
				EXEC spProject_AddNewProjectVersion @ProjectGuid;
			END
		
			UPDATE	Template
			SET		[name] = @Name, 
					Template_type_id = @ProjectTypeID, 
					Supplier_GUID = @SupplierGuid,
					Content_Bookmark = @ContentBookmark
			WHERE	Template_Guid = @ProjectGuid;
		END

		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE Template
			SET Modified_Date = getUTCdate(),
				Modified_By = @UserGuid,
				Template_Version = Template_Version + 1,
				Comment = NULL
			WHERE Template_Guid = @ProjectGuid;
		END
	
	COMMIT
	
GO

