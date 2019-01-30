truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.5.0.18');
go

-- Duplicate script in 8.6.0.6

ALTER PROCEDURE [dbo].[spDataSource_RemoveDataSource]
	@DataServiceGuid uniqueidentifier
as
	DELETE data_object_key WHERE data_object_id in (
		SELECT data_object_id FROM data_object WHERE data_service_guid = @DataServiceGuid
	)
	DELETE data_object WHERE data_service_guid = @DataServiceGuid
	DELETE data_service WHERE data_service_guid = @DataServiceGuid
GO
ALTER PROCEDURE [dbo].[spUser_AddToPasswordHistory]
	@UserId int,
	@PwdHash varchar(1000)
AS
BEGIN
	DECLARE @HistoryLimit integer
	DECLARE @BusinessUnitGuid uniqueidentifier
	DECLARE @UserGuid uniqueidentifier

	SELECT	@BusinessUnitGuid = Business_Unit_GUID,
			@UserGuid = User_Guid
	FROM	Intelledox_User
	WHERE	User_ID = @UserId;

	SET @HistoryLimit = (SELECT Global_Options.OptionValue 
						FROM Global_Options 
						WHERE  Global_Options.BusinessUnitGuid = @BusinessUnitGuid
							AND Global_Options.OptionCode = 'PASSWORD_HISTORY_COUNT')

	IF (@HistoryLimit > 0)
	BEGIN
		INSERT INTO [Password_History] (User_Guid, pwdhash)
		VALUES (@UserGuid, @PwdHash)

		DELETE FROM Password_History
		WHERE id NOT IN (SELECT TOP (@HistoryLimit) id 
						FROM Password_History 
						WHERE User_Guid = @UserGuid
						ORDER BY DateCreatedUtc DESC)
			AND User_Guid = @UserGuid;
	END
END
GO
