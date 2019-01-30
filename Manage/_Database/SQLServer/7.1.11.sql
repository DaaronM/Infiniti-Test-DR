/*
** Database Update package 7.1.11
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.11')
go

--1978
CREATE procedure [dbo].[spUsers_DefaultUserGroup]
	@UserGuid uniqueidentifier = null
AS
	SELECT	b.User_Group_Id, b.Group_Guid
	FROM	Intelledox_User IxUser
			INNER JOIN	User_Group_Subscription c on IxUser.[User_ID] = c.[User_ID]
			INNER JOIN	User_Group b on c.User_Group_ID = b.User_Group_ID
	WHERE	c.Default_Group = '1'
			AND (IxUser.User_Guid = @UserGuid);
GO


