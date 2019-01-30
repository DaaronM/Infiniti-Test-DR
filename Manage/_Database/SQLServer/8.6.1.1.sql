truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.1.1');
go

CREATE PROCEDURE [dbo].[spTenant_GetEmails]
	@BusinessUnitGUID uniqueidentifier = NULL
	
AS

SELECT	DISTINCT Email_Address 
FROM	Intelledox_User
		INNER JOIN Address_Book ON Intelledox_User.Address_Id = Address_Book.Address_Id
		INNER JOIN User_Role ON Intelledox_User.User_Guid = User_Role.UserGuid
		INNER JOIN Role_Permission ON User_Role.RoleGuid = Role_Permission.RoleGuid
		INNER JOIN Permission ON Permission.PermissionGuid = Role_Permission.PermissionGuid
		WHERE Disabled = 0
		AND (Business_Unit_GUID = @BusinessUnitGUID OR @BusinessUnitGUID IS NULL)
		AND ISNULL(Email_Address, '') <> ''
UNION
SELECT	DISTINCT Email_Address 
FROM	Intelledox_User
		INNER JOIN Address_Book ON Intelledox_User.Address_Id = Address_Book.Address_Id
		INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
		INNER JOIN User_Group_Role ON User_Group_Subscription.GroupGuid = User_Group_Role.GroupGuid
		INNER JOIN Role_Permission ON User_Group_Role.RoleGuid = Role_Permission.RoleGuid
		INNER JOIN Permission ON Permission.PermissionGuid = Role_Permission.PermissionGuid
		WHERE Disabled = 0
		AND (Business_Unit_GUID = @BusinessUnitGUID OR @BusinessUnitGUID IS NULL)
		AND ISNULL(Email_Address, '') <> ''
GO

ALTER PROCEDURE [dbo].[spTenant_UpdateTenant]
	@BusinessUnitID uniqueidentifier,
	@TenantName nvarchar(200) = '',
	@TenantType int

AS

	UPDATE	Business_Unit
	SET		NAME = @TenantName,
			TenantType = @TenantType
	WHERE	Business_Unit_GUID = @BusinessUnitID;

GO
