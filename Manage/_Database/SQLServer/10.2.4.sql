truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.2.4');
GO

ALTER VIEW [dbo].[vwInteractionLog_Save]
AS
SELECT il.Business_Unit_GUID, s.Log_Guid, s.LastSaveTimeUTC, il.Form, il.Page AS LastSavePage, s.SaveCount
FROM dbo.vwInteractionLog il JOIN
  (SELECT Log_Guid, COUNT(LOG_GUID) As SaveCount, MAX(FocusTimeUTC) AS LastSaveTimeUTC
   FROM dbo.Analytics_InteractionLog
   WHERE EventType = 'save'
   GROUP BY Log_Guid) s ON il.Log_Guid = s.Log_Guid AND il.FocusTimeUTC = s.LastSaveTimeUTC

GO
DROP INDEX IX_Intelledox_User_Username ON dbo.Intelledox_User
GO
CREATE UNIQUE NONCLUSTERED INDEX IX_Intelledox_User_Username ON dbo.Intelledox_User
	(
	Username,
	Business_Unit_GUID
	)
GO
ALTER procedure [dbo].[spUsers_UserByUsername]
	@BusinessUnitGuid uniqueidentifier = null,
	@UserName nvarchar(256)
AS
	IF @BusinessUnitGuid IS NULL
	BEGIN
		-- Exclude tenants that have their own urls
		SELECT	Intelledox_User.*, Business_Unit.DefaultLanguage
		FROM	Intelledox_User
				INNER JOIN Business_Unit ON Intelledox_User.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				INNER JOIN Global_Options ON Business_Unit.Business_Unit_Guid = Global_Options.BusinessUnitGuid
		WHERE	Intelledox_User.Username = @UserName
				AND Global_Options.OptionCode = 'PRODUCER_URL'
				AND Global_Options.OptionValue = '';
	END
	ELSE
	BEGIN
		SELECT	Intelledox_User.*, Business_Unit.DefaultLanguage
		FROM	Intelledox_User
				INNER JOIN Business_Unit ON Intelledox_User.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
		WHERE	Intelledox_User.Username = @UserName
				AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid;
	END
GO
ALTER procedure [dbo].[spUsers_ConfirmUniqueUsername]
	@BusinessUnitGuid uniqueidentifier,
	@UserGuid uniqueidentifier,
	@Username nvarchar(256) = ''
as
	IF EXISTS(SELECT 1 
		FROM Global_Options
		WHERE Global_Options.BusinessUnitGuid = @BusinessUnitGuid
			AND Global_Options.OptionCode = 'PRODUCER_URL'
			AND Global_Options.OptionValue <> '')
	BEGIN
		SELECT	COUNT(*)
		FROM	Intelledox_User
		WHERE	Intelledox_User.Username = @UserName
				AND Intelledox_User.User_Guid <> @UserGuid
				AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
	END
	ELSE
	BEGIN
		SELECT	COUNT(*)
		FROM	Intelledox_User
				INNER JOIN Business_Unit ON Intelledox_User.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				INNER JOIN Global_Options ON Business_Unit.Business_Unit_Guid = Global_Options.BusinessUnitGuid
		WHERE	Intelledox_User.Username = @UserName
				AND Intelledox_User.User_Guid <> @UserGuid
				AND Global_Options.OptionCode = 'PRODUCER_URL'
				AND Global_Options.OptionValue = '';
	END
GO
ALTER PROCEDURE [dbo].[spUser_IsLockedOut]
	@UserGuid uniqueidentifier
AS
BEGIN
	SET NOCOUNT ON;

	SELECT COUNT(*)
	FROM Intelledox_User
	WHERE Intelledox_User.User_Guid = @UserGuid AND
		Intelledox_User.Locked_Until_Utc IS NOT NULL AND
		Intelledox_User.Locked_Until_Utc > GETUTCDATE()
END
GO
ALTER PROCEDURE [dbo].[spUser_SetLockedOutUtc]
	@UserGuid uniqueidentifier,
	@LockedOutUtc DateTime
AS
	UPDATE Intelledox_User
	SET [Locked_Until_Utc] = @LockedOutUtc
	WHERE User_Guid = @UserGuid
GO
ALTER PROCEDURE [dbo].[spUser_ClearInvalidLogonAttempts]
	@UserGuid uniqueidentifier
AS
BEGIN
	UPDATE Intelledox_User
	SET [Invalid_Logon_Attempts] = 0
	WHERE User_Guid = @UserGuid
END
GO
ALTER PROCEDURE [dbo].[spUser_InvalidLogonAttempt]
	@UserGuid uniqueidentifier
AS
BEGIN
	UPDATE Intelledox_User
	SET [Invalid_Logon_Attempts] = [Invalid_Logon_Attempts] + 1
	WHERE User_Guid = @UserGuid
END
GO
ALTER PROCEDURE [dbo].[spUsers_UserByUsernameOrEmail]
	@BusinessUnitGuid uniqueidentifier,
	@UsernameOrEmail nvarchar(256)
AS
BEGIN
	IF EXISTS(SELECT 1 
		FROM Global_Options
		WHERE Global_Options.BusinessUnitGuid = @BusinessUnitGuid
			AND Global_Options.OptionCode = 'PRODUCER_URL'
			AND Global_Options.OptionValue <> '')
	BEGIN
		SELECT Intelledox_User.*, Address_Book.Email_Address
		FROM Intelledox_User
			LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
		WHERE (Email_Address = @UsernameOrEmail OR Username = @UsernameOrEmail)
			AND Intelledox_User.Disabled = 0
			AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid;
	END
	ELSE
	BEGIN
		-- Exclude tenants that have their own urls
		SELECT Intelledox_User.*, Address_Book.Email_Address
		FROM Intelledox_User
			INNER JOIN Business_Unit ON Intelledox_User.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			INNER JOIN Global_Options ON Business_Unit.Business_Unit_Guid = Global_Options.BusinessUnitGuid
			LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
		WHERE (Email_Address = @UsernameOrEmail OR Username = @UsernameOrEmail)
			AND Intelledox_User.Disabled = 0
			AND Global_Options.OptionCode = 'PRODUCER_URL'
			AND Global_Options.OptionValue = '';
	END
END
GO

DELETE FROM Routing_ElementType WHERE RoutingElementTypeId = '7D64B0EA-A4BF-44A2-ADFA-F5C41B8570AC'
GO
