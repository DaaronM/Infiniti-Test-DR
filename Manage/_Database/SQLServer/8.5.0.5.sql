truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.5.0.5');
go

CREATE PROCEDURE [dbo].[spLicense_GetUsage] 
	@BusinessUnitGuid uniqueidentifier,
	@LicenseKey varchar(1000),
	@ErrorCode int = 0 output

AS

BEGIN
	SET NOCOUNT ON;

	SELECT COUNT(1) 
	FROM License_Key
	WHERE LicenseKey = @LicenseKey
	AND BusinessUnitGuid <> @BusinessUnitGuid;
	
	SET @ErrorCode = @@ERROR;
END
GO

