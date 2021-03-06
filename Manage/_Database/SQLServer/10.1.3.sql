truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.1.3');
GO

CREATE TABLE [dbo].[UserProfileMapTmp](
    [ProfileMapGuid] UNIQUEIDENTIFIER NOT NULL,
	[Business_Unit_GUID] [uniqueidentifier] NOT NULL,
	[FieldFrom] [nvarchar](255) NULL,
	[FieldTo] [nvarchar](255) NULL,
	[CustomFieldId] INT NULL
CONSTRAINT [PK_UserProfileMapTmp] PRIMARY KEY CLUSTERED 
	(ProfileMapGuid ASC)
	 )
GO

INSERT INTO UserProfileMapTmp(ProfileMapGuid, Business_Unit_GUID,
	FieldFrom,  FieldTo, CustomFieldId)
SELECT NEWID(), Business_Unit_GUID,
	FieldFrom, FieldTo, NULL
FROM UserProfileMap
GO

DROP TABLE [dbo].[UserProfileMap]
GO

EXEC sp_rename 'UserProfileMapTmp', 'UserProfileMap'
GO

EXEC sp_rename 'PK_UserProfileMapTmp', 'PK_UserProfileMap'
GO

ALTER PROCEDURE [dbo].[spCustomField_RemoveCustomField]
	@CustomFieldID int,
	@ErrorCode int = 0 output
AS
	DELETE Custom_Field
	WHERE Custom_Field_ID = @CustomFieldID

	DELETE UserProfileMap
	WHERE CustomFieldId = @CustomFieldID
	
	SET @errorcode = @@error
GO

ALTER PROCEDURE [dbo].[spProject_UnlockProject]
	@ProjectGuid uniqueidentifier,
	@VersionComment nvarchar(max) = '',
	@UserGuid uniqueidentifier,
	@ForceUnlock bit
AS
	BEGIN TRAN
		--Allows unlock either by any user if its a force unlock OR by the same user who has currently locked the project if general unlock
		IF @ForceUnlock = 1 OR (@ForceUnlock = 0 AND EXISTS(SELECT LockedByUserGuid FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid = @UserGuid))
		BEGIN
			DECLARE @FinalComment AS NVARCHAR(MAX) = ISNULL((SELECT Comment FROM Template WHERE Template_Guid = @ProjectGuid),'')
			
			IF LEN(@VersionComment) > 0
			BEGIN
				SET @FinalComment = @VersionComment + CHAR(13) + @FinalComment
			END

			UPDATE	Template
			SET		LockedByUserGuid = NULL,
					Comment = @FinalComment,
					IsMajorVersion = 1
			WHERE	Template_Guid = @ProjectGuid;
		END
	COMMIT
GO
