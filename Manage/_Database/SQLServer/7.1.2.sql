/*
** Database Update package 7.1.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.2')
go

--1965
ALTER procedure [dbo].[spTemplate_RoutingElementTypeList]
	@RoutingTypeId uniqueidentifier
AS
	SELECT	*
	FROM	Routing_ElementType
	WHERE	RoutingTypeId = @RoutingTypeId
	ORDER BY ElementTypeDescription;
GO


--1966
DELETE FROM	Content_Item_Placeholder
WHERE	PlaceholderName = '_GoBack'
GO


--1967
ALTER procedure [dbo].[spUsers_RemoveUser]
	@UserGuid uniqueidentifier
AS
	DECLARE @UserId int;
	
	SELECT	@UserId = [User_Id]
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;
	
	DELETE	Address_Book WHERE [User_Id] = @UserId;
	DELETE	User_Address_Book WHERE [User_Id] = @UserId;
	DELETE	User_Group_Subscription WHERE [User_Id] = @UserId;
	DELETE	User_Signoff WHERE [User_Id] = @UserId;
	DELETE	Intelledox_User WHERE User_Guid = @UserGuid;
GO


