truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.2.0');
go

ALTER TABLE Business_Unit
ADD [TenantLogo] [varbinary](max) NULL
GO

CREATE PROCEDURE [dbo].[spTenant_GetTenantLogoBinary] (
	@BusinessUnitGuid uniqueidentifier
)

AS
	SELECT	TenantLogo AS [Binary]
	FROM	Business_Unit
	WHERE	Business_Unit_GUID = @BusinessUnitGuid;
GO

CREATE PROCEDURE [dbo].[spTenant_RemoveLogo]
	@BusinessUnitID uniqueidentifier

AS

	UPDATE	Business_Unit
	SET		TenantLogo = NULL
	WHERE	Business_Unit_GUID = @BusinessUnitID;
GO

CREATE PROCEDURE [dbo].[spUsers_UserCount]
	@BusinessUnitGuid uniqueidentifier
	
AS

BEGIN

	SELECT COUNT(Intelledox_User.User_Guid) 
	FROM Intelledox_User
	WHERE Business_Unit_GUID = @BusinessUnitGuid
	AND IsGuest = 0
	AND Disabled = 0;

END
GO










