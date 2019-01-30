truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.1.10');
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE Name = 'spLibrary_GetCustomFieldBinary')
BEGIN
	DROP PROCEDURE spLibrary_GetCustomFieldBinary;
END
GO
CREATE PROCEDURE [dbo].[spLibrary_GetCustomFieldBinary] (
	@UserGuid as uniqueidentifier,
	@DataGuid as uniqueidentifier
)
AS
	DECLARE @DataGuidString NVARCHAR(36)

	SET @DataGuidString = CAST(@DataGuid as NVARCHAR(36));

	IF EXISTS(
		-- Profile
		SELECT	Intelledox_User.User_Guid
		FROM	Intelledox_User
				INNER JOIN Address_Book_Custom_Field ON Intelledox_User.Address_ID = Address_Book_Custom_Field.Address_ID
		WHERE	Intelledox_User.User_Guid = @UserGuid
				AND Address_Book_Custom_Field.Custom_Value = @DataGuidString) OR
		EXISTS(
		-- Contact
		SELECT	Intelledox_User.User_Guid
		FROM	Intelledox_User
				INNER JOIN User_Address_Book ON Intelledox_User.User_ID = User_Address_Book.User_ID
				INNER JOIN Address_Book_Custom_Field ON User_Address_Book.Address_ID = Address_Book_Custom_Field.Address_ID
		WHERE	Intelledox_User.User_Guid = @UserGuid
				AND Address_Book_Custom_Field.Custom_Value = @DataGuidString)
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
		WHERE	ContentData_Guid = @DataGuid;
	END
GO
