truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.4.0.1');
go
ALTER VIEW [dbo].[vwTemplateVersion]
AS
	SELECT	Template_Version.Template_Version, 
			Template_Version.Template_Guid,
			Template_Version.Modified_Date,
			Template_Version.Comment,
			Template.Template_Type_ID,
			Template.LockedByUserGuid,
			Template_Version.IsMajorVersion,
			Intelledox_User.Username,
			Address_Book.First_Name + ' ' + Address_Book.Last_Name AS Full_Name,
			CASE (SELECT COUNT(*)
					FROM Template_Group 
					WHERE (Template_Group.Template_Guid = Template_Version.Template_Guid
								AND Template_Group.Template_Version = Template_Version.Template_Version)
							OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
								AND Template_Group.Layout_Version = Template_Version.Template_Version)) 
				WHEN 0
				THEN 0
				ELSE 1
			END AS InUse,
			0 AS Latest
		FROM	Template_Version
			INNER JOIN Template ON Template_Version.Template_Guid = Template.Template_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template_Version.Modified_By
			LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
	UNION ALL
		SELECT	Template.Template_Version, 
				Template.Template_Guid,
				Template.Modified_Date,
				Template.Comment,
				Template.Template_Type_ID,
				Template.LockedByUserGuid,
				Template.IsMajorVersion,
				Intelledox_User.Username,
				Address_Book.First_Name + ' ' + Address_Book.Last_Name AS Full_Name,
				CASE (SELECT COUNT(*)
						FROM Template_Group 
						WHERE (Template_Group.Template_Guid = Template.Template_Guid
									AND (Template_Group.Template_Version = Template.Template_Version OR ISNULL(Template_Group.Template_Version, '0') = '0'))
							OR (Template_Group.Layout_Guid = Template.Template_Guid
									AND (Template_Group.Layout_Version = Template.Template_Version OR ISNULL(Template_Group.Layout_Version, '0') = '0')))
					WHEN 0
					THEN 0
					ELSE 1
				END AS InUse,
				1 AS Latest
		FROM	Template
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
			LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID;

GO
ALTER procedure [dbo].[spProject_GetProjectVersions]
	@ProjectGuid uniqueidentifier
AS
		SELECT vwTemplateVersion.Template_Version, 
			vwTemplateVersion.Modified_Date,
			vwTemplateVersion.Username,
			vwTemplateVersion.Full_Name,
			vwTemplateVersion.Comment,
			vwTemplateVersion.LockedByUserGuid,
			vwTemplateVersion.InUse
		FROM	vwTemplateVersion
		WHERE	vwTemplateVersion.Template_Guid = @ProjectGuid
	ORDER BY Modified_Date DESC;

GO

ALTER TABLE [Business_Unit]
ADD IdentifyBusinessUnit integer NOT NULL UNIQUE
DEFAULT FLOOR(RAND(convert(varbinary, newid())) * (89999)) + 10000,
CONSTRAINT BUIdentityRange CHECK (IdentifyBusinessUnit >= 10000 AND IdentifyBusinessUnit <= 99999)
GO

CREATE PROCEDURE [dbo].[spTenant_IdentifyBusinessUnit]
	@BusinessUnitIdentifier int
AS
	SELECT	*
	FROM	Business_Unit
	WHERE	IdentifyBusinessUnit = @BusinessUnitIdentifier;
GO

CREATE PROCEDURE [dbo].[spUsers_UserGuestUser]
	@BusinessUnitGuid uniqueidentifier
AS
	SELECT	*
	FROM	Intelledox_User
	WHERE	Business_Unit_GUID = @BusinessUnitGuid AND IsGuest = 1;
GO


