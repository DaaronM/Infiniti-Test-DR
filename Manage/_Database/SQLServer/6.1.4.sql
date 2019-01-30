/*
** Database Update package 6.1.4
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.4')
go

--1882
ALTER TABLE dbo.Intelledox_User ADD
	[Disabled] bit NULL
GO
ALTER TABLE dbo.Intelledox_User ADD CONSTRAINT
	DF_Intelledox_User_Disabled DEFAULT 0 FOR [Disabled]
GO
UPDATE	dbo.Intelledox_User
SET		[Disabled] = 0
WHERE	[Disabled] IS NULL;
GO
ALTER procedure [dbo].[spUsers_UpdateUser]
	@UserID int,
	@Username nvarchar(50),
	@Password nvarchar(1000),
	@NewID int = 0 output,
	@WinNT_User char(1),
	@BusinessUnitGUID uniqueidentifier,
	@User_GUID uniqueidentifier,
	@SelectedTheme nvarchar(100),
	@ChangePassword int,
	@PasswordSalt nvarchar(128),
	@PasswordFormat int,
	@Disabled int,
	@ErrorCode int = 0 output
as
	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled])
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled);
		
		select @NewID = @@identity;

		INSERT INTO User_Group_Subscription(User_ID, User_Group_ID, Default_Group)
		SELECT	@NewID, User_Group.User_Group_ID, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = '1';
	end
	else
	begin
		UPDATE Intelledox_User
		SET Username = @Username,  
			PwdHash = @Password, 
			WinNT_User = @WinNT_User,
			SelectedTheme = @SelectedTheme,
			ChangePassword = @ChangePassword,
			PwdSalt = @PasswordSalt,
			PwdFormat = @PasswordFormat,
			[Disabled] = @Disabled
		WHERE [User_ID] = @UserID;
	end

	set @ErrorCode = @@error;
GO


--1883

INSERT INTO global_options (OptionCode, OptionDescription, OptionValue)
VALUES ('MAX_VERSIONS', 'Maximum number of versions that are stored of a project', '10');
GO


ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier
as
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Binary,
			Project_Definition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Binary,
			Template.Project_Definition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		IF (SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT MIN(Template_Version) 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0)
				AND Template_Guid = @ProjectGuid;
		END
		
	COMMIT
GO


--1884
DECLARE @BusinessUnitGuid uniqueidentifier;

SELECT TOP 1 @BusinessUnitGuid = Business_Unit_Guid
FROM	dbo.Business_Unit;

SET IDENTITY_INSERT dbo.intelledox_user ON;

INSERT INTO intelledox_user([User_Id], Username, pwdhash, WinNT_User, Business_Unit_Guid, User_Guid, 
	SelectedTheme, ChangePassword, PwdFormat, PwdSalt, [Disabled])
VALUES (-1, 'Guest', '', 0, @BusinessUnitGuid, '99999999-9999-9999-9999-999999999999',
	'', 0, 2, '', 1);

SET IDENTITY_INSERT dbo.intelledox_user OFF;

INSERT INTO User_Group_Subscription([User_Id], User_Group_Id, Default_Group)
SELECT	-1, User_Group_Id, 1
FROM	User_Group
WHERE	Name = 'Intelledox Users';

INSERT INTO Address_Book (addresstype_id, [user_id], usergroup_id, address_reference,
	prefix, first_name, last_name, full_name, salutation_name, title,
	organisation_name, phone_number, fax_number, email_address,
	street_address_1, street_address_2, street_address_suburb, street_address_state,
	street_address_postcode, street_address_country, postal_address_1, postal_address_2,
	postal_address_suburb, postal_address_state, postal_address_postcode, postal_address_country)
VALUES (0, -1, 0, '',
	'', '', '', '', '', '',
	'', '', '', '',
	'', '', '', '',
	'', '', '', '',
	'', '', '', '');
GO
INSERT INTO Global_Options(OptionCode, OptionDescription, OptionValue)
VALUES ('ANONYMOUS_ACCESS', 'Allow anonymous (Guest) access', 0);
GO

UPDATE	Address_Book
SET		AddressType_Id = 0
WHERE	AddressType_Id IS NULL;

UPDATE	Address_Book
SET		[User_Id] = 0
WHERE	[User_Id] IS NULL;

UPDATE	Address_Book
SET		[UserGroup_Id] = 0
WHERE	[UserGroup_Id] IS NULL;
GO
