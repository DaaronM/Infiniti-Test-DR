truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.0.8');
go

CREATE PROCEDURE [dbo].[spMultiTenantAdmin_UserByUserGuid]
	@UserGuid uniqueidentifier
AS
	SELECT	MultiTenantPortal_Admin.*
	FROM	MultiTenantPortal_Admin
	WHERE	UserGuid = @UserGuid;
GO
