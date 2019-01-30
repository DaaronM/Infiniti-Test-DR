/*
** Database Update package 8.2.3.30
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.3.33');
go

-- Added Phone number and Email address
ALTER VIEW [dbo].[vwUsersInGroups]
AS
SELECT      ug.Name as GroupName, ug.Group_Guid,
			u.UserName as Username, u.User_Guid, u.Business_unit_Guid,
			ab.Full_Name as FullName, ab.First_Name, ab.Last_Name, ab.Prefix,
			ab.Phone_Number, ab.Email_Address
FROM	    User_Group_Subscription ugs
LEFT JOIN	User_Group ug  ON ugs.GroupGuid = ug.Group_Guid
LEFT JOIN   Intelledox_User u ON ugs.UserGuid = u.User_Guid
LEFT JOIN	Address_Book ab on ab.Address_ID = u.Address_ID
GO

