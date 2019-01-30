/*
** Database Update package 8.0.0.4
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0.4');
go

--2032

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProviderSettings_ElementType]') AND type in (N'U'))
DROP TABLE [dbo].[ProviderSettings_ElementType]
GO

GO

CREATE TABLE [dbo].[ProviderSettings_ElementType](
	[ProviderSettingsElementTypeId] [uniqueidentifier] NOT NULL,
	[ProviderSettingsTypeId] [uniqueidentifier] NOT NULL,
	[DescriptionDefault] [nvarchar](255) NULL,
	[Encrypt] [bit] NULL,
	[SortOrder] [numeric](18, 0) NULL,
	[ElementValue] [nvarchar](max) NULL,
 CONSTRAINT [PK_ProviderSettings_ElementType] PRIMARY KEY CLUSTERED 
(
	[ProviderSettingsElementTypeId] ASC
)
)

GO

--2033
ALTER TABLE Routing_Type
	ADD RunForAllProjects bit NOT NULL default (0)
GO
ALTER PROCEDURE [dbo].[spRouting_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ProviderType int,
	@RunForAllProjects bit
AS
	IF NOT EXISTS(SELECT * FROM Routing_Type WHERE RoutingTypeId = @id)
	BEGIN
		INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription, ProviderType, RunForAllProjects)
		VALUES	(@id, @Description, @ProviderType, @RunForAllProjects);
	END
GO
UPDATE	Routing_ElementType
SET		ElementTypeDescription = 'Duplex'
WHERE	RoutingElementTypeId = 'AB252F08-3FE7-4D3A-A447-0B4134A5622A';
GO
UPDATE	Routing_Type
SET		ProviderType = 4
WHERE	RoutingTypeId = 'D3F8B0A0-754A-4CAF-B840-B75377577890';
GO
DELETE FROM Routing_ElementType
WHERE	RoutingElementTypeId = '35F94575-AC26-498D-8F5C-9E4FFEE52A0F';
GO

--2034
UPDATE	Routing_Type
SET		ProviderType = 4
WHERE	RoutingTypeId = '230DD56C-0018-4D49-945E-5B6E5B08EAF6';
GO


--2035
ALTER procedure [dbo].[spUsers_UserData]
	@BusinessUnitGUID nvarchar(50),
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@ErrorCode int = 0 output
as
	SET NOCOUNT ON;

	DECLARE @ColNames nvarchar(MAX);
	
	-- Find the Custom_Fields
	-- Will look like "[CustomField1],[CustomField2],[Custom_Field]"
	SET @ColNames = '[' + (
		SELECT Title + '],[' 
		FROM Custom_Field 
		WHERE Validation_Type <> 3
		FOR XML PATH('')) ;

	IF (@ColNames IS NULL)
	BEGIN
		SELECT Username, 
				First_Name,
				Last_Name,
				SelectedTheme,
				Inactive,
				Full_Name,
				Salutation_Name,
				Title,
				Organisation_Name,
				Phone_Number,
				Fax_Number,
				Email_Address,
				Street_Address_1,
				Street_Address_2,
				Street_Address_Suburb,
				Street_Address_State,
				Street_Address_Postcode,
				Street_Address_Country,
				Postal_Address_1,
				Postal_Address_2,
				Postal_Address_Suburb,
				Postal_Address_State,
				Postal_Address_Postcode,
				Postal_Address_Country
			FROM (
				SELECT Intelledox_User.Username, 
					Intelledox_User.SelectedTheme,
					Intelledox_User.[Disabled] As Inactive,
					Address_Book.First_Name,
					Address_Book.Last_Name,
					Address_Book.Full_Name,
					Address_Book.Salutation_Name,
					Address_Book.Title,
					Address_Book.Organisation_Name,
					Address_Book.Phone_Number,
					Address_Book.Fax_Number,
					Address_Book.Email_Address,
					Address_Book.Street_Address_1,
					Address_Book.Street_Address_2,
					Address_Book.Street_Address_Suburb,
					Address_Book.Street_Address_State,
					Address_Book.Street_Address_Postcode,
					Address_Book.Street_Address_Country,
					Address_Book.Postal_Address_1,
					Address_Book.Postal_Address_2,
					Address_Book.Postal_Address_Suburb,
					Address_Book.Postal_Address_State,
					Address_Book.Postal_Address_Postcode,
					Address_Book.Postal_Address_Country
				FROM Intelledox_User
					LEFT JOIN User_Group_Subscription ON Intelledox_User.[User_Guid] = User_Group_Subscription.[UserGuid]
					LEFT JOIN User_Group ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
					LEFT JOIN Address_Book ON Intelledox_User.[Address_ID] = Address_Book.[Address_ID] 
				WHERE (@Username = '' OR Intelledox_User.Username LIKE @Username + '%')
					AND Intelledox_User.Business_Unit_GUID = CONVERT(uniqueidentifier, @BusinessUnitGUID)
					AND	(@UserGroupID = 0 
						OR User_Group.User_Group_ID = @UserGroupID
						OR (@UserGroupID = -1 AND User_Group.User_Group_ID IS NULL))
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND Intelledox_User.[Disabled] = 0)
						OR (@ShowActive = 2 AND Intelledox_User.[Disabled] = 1))
				
				GROUP BY Intelledox_User.Username, 
					Intelledox_User.SelectedTheme,
					Intelledox_User.[Disabled],
					Address_Book.First_Name,
					Address_Book.Last_Name,
					Address_Book.Full_Name,
					Address_Book.Salutation_Name,
					Address_Book.Title,
					Address_Book.Organisation_Name,
					Address_Book.Phone_Number,
					Address_Book.Fax_Number,
					Address_Book.Email_Address,
					Address_Book.Street_Address_1,
					Address_Book.Street_Address_2,
					Address_Book.Street_Address_Suburb,
					Address_Book.Street_Address_State,
					Address_Book.Street_Address_Postcode,
					Address_Book.Street_Address_Country,
					Address_Book.Postal_Address_1,
					Address_Book.Postal_Address_2,
					Address_Book.Postal_Address_Suburb,
					Address_Book.Postal_Address_State,
					Address_Book.Postal_Address_Postcode,
					Address_Book.Postal_Address_Country
				) Data
			ORDER BY Username;
	END
	ELSE
	BEGIN
		-- Cut off the final ",["
		SET @ColNames = SUBSTRING(@ColNames, 1, LEN(@ColNames)-2);
	
		DECLARE @SQL nvarchar(MAX);
		SET @SQL = 'SELECT Username, 
				First_Name,
				Last_Name,
				SelectedTheme,
				Inactive,
				Full_Name,
				Salutation_Name,
				Title,
				Organisation_Name,
				Phone_Number,
				Fax_Number,
				Email_Address,
				Street_Address_1,
				Street_Address_2,
				Street_Address_Suburb,
				Street_Address_State,
				Street_Address_Postcode,
				Street_Address_Country,
				Postal_Address_1,
				Postal_Address_2,
				Postal_Address_Suburb,
				Postal_Address_State,
				Postal_Address_Postcode,
				Postal_Address_Country, 
				' + @ColNames + ' 
			FROM (
				SELECT Intelledox_User.Username, 
					Intelledox_User.SelectedTheme,
					Intelledox_User.[Disabled] As Inactive,
					Address_Book.First_Name,
					Address_Book.Last_Name,
					Address_Book.Full_Name,
					Address_Book.Salutation_Name,
					Address_Book.Title,
					Address_Book.Organisation_Name,
					Address_Book.Phone_Number,
					Address_Book.Fax_Number,
					Address_Book.Email_Address,
					Address_Book.Street_Address_1,
					Address_Book.Street_Address_2,
					Address_Book.Street_Address_Suburb,
					Address_Book.Street_Address_State,
					Address_Book.Street_Address_Postcode,
					Address_Book.Street_Address_Country,
					Address_Book.Postal_Address_1,
					Address_Book.Postal_Address_2,
					Address_Book.Postal_Address_Suburb,
					Address_Book.Postal_Address_State,
					Address_Book.Postal_Address_Postcode,
					Address_Book.Postal_Address_Country, 
					Custom_Field.Title As CustomFieldTitle,
					ISNULL(Address_Book_Custom_Field.Custom_Value, '''') AS Custom_Value
				FROM Intelledox_User
					LEFT JOIN User_Group_Subscription ON Intelledox_User.[User_Guid] = User_Group_Subscription.[UserGuid]
					LEFT JOIN User_Group ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
					LEFT JOIN Address_Book ON Intelledox_User.[Address_ID] = Address_Book.[Address_ID] 
					LEFT JOIN Address_Book_Custom_Field ON Address_Book.Address_ID = Address_Book_Custom_Field.Address_ID
					LEFT JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_ID = Custom_Field.Custom_Field_ID
						AND Custom_Field.Validation_Type <> 3
				WHERE (''' + @Username + ''' = '''' OR Intelledox_User.Username LIKE ''' + @Username + '%'')
					AND Intelledox_User.Business_Unit_GUID = CONVERT(uniqueidentifier, ''' + @BusinessUnitGUID + ''')
					AND	(' + CONVERT(varchar, @UserGroupID) + ' = 0 
						OR User_Group.User_Group_ID = ' + CONVERT(varchar, @UserGroupID) + '
						OR (' + CONVERT(varchar, @UserGroupID) + ' = -1 AND User_Group.User_Group_ID IS NULL))
					AND (' + CONVERT(varchar, @ShowActive) + ' = 0 
						OR (' + CONVERT(varchar, @ShowActive) + ' = 1 AND Intelledox_User.[Disabled] = 0)
						OR (' + CONVERT(varchar, @ShowActive) + ' = 2 AND Intelledox_User.[Disabled] = 1))
				
				GROUP BY Intelledox_User.Username, 
					Intelledox_User.SelectedTheme,
					Intelledox_User.[Disabled],
					Address_Book.First_Name,
					Address_Book.Last_Name,
					Address_Book.Full_Name,
					Address_Book.Salutation_Name,
					Address_Book.Title,
					Address_Book.Organisation_Name,
					Address_Book.Phone_Number,
					Address_Book.Fax_Number,
					Address_Book.Email_Address,
					Address_Book.Street_Address_1,
					Address_Book.Street_Address_2,
					Address_Book.Street_Address_Suburb,
					Address_Book.Street_Address_State,
					Address_Book.Street_Address_Postcode,
					Address_Book.Street_Address_Country,
					Address_Book.Postal_Address_1,
					Address_Book.Postal_Address_2,
					Address_Book.Postal_Address_Suburb,
					Address_Book.Postal_Address_State,
					Address_Book.Postal_Address_Postcode,
					Address_Book.Postal_Address_Country, 
					Custom_Field.Title,
					ISNULL(Address_Book_Custom_Field.Custom_Value, '''')
				) Data
			PIVOT (MAX(Custom_Value) FOR CustomFieldTitle IN (' + @ColNames + ')) AS PivotedData
			ORDER BY Username';
		
			--SELECT @SQL
		EXECUTE sp_executesql @SQL;
	END

	SET @ErrorCode = @@error;
GO

