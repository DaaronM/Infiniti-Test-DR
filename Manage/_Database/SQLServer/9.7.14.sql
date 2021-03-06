truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.7.14');
go
ALTER PROCEDURE [dbo].[spUsers_UserCount]
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT SUM(CASE WHEN IsGuest = 0 AND Disabled = 0 THEN 1 ELSE 0 END) 
	FROM Intelledox_User
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END
GO
