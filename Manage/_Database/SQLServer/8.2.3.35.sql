truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.3.35');
go
UPDATE	user_group
SET		Address_ID = 0
WHERE	Address_ID is null;

UPDATE	intelledox_user
SET		Address_ID = 0
WHERE	Address_ID is null;
GO
CREATE procedure [dbo].[spAddBk_UserAddressListHasAccess]
	@UserGuid uniqueidentifier,
	@AddressId int
AS
	SELECT	COUNT(*)
	FROM	User_Address_Book
			INNER JOIN Intelledox_User ON User_Address_Book.User_ID = Intelledox_User.User_ID
	WHERE	Intelledox_User.User_Guid = @UserGuid
			AND	User_Address_Book.Address_ID = @AddressId;
GO
