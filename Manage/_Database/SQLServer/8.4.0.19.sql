truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.4.0.19');
go
ALTER procedure [dbo].[spUsers_UserData]
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@FirstName nvarchar(50) = '',
	@LastName nvarchar(50) = '',
	@ErrorCode int = 0 output

AS

	SET NOCOUNT ON;

	DECLARE @ColNames nvarchar(MAX);
	
	-- Find the Custom_Fields
	-- Will look like "[CustomField1],[CustomField2],[Custom_Field."
	SET @ColNames = '[' + (
		SELECT Title + '],[' 
		FROM Custom_Field 
		WHERE Validation_Type <> 3
			AND BusinessUnitGUID = @BusinessUnitGUID
		FOR XML PATH('')) ;
	-- Cut off the final ",["
	SET @ColNames = SUBSTRING(@ColNames, 1, LEN(@ColNames)-2);
	SET @Username = REPLACE(@Username, '''', '''''');
	SET @FirstName = REPLACE(@FirstName, '''', '''''');
	SET @LastName = REPLACE(@LastName, '''', '''''');

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
			Postal_Address_Country 
			' + IsNull(',' + @ColNames, '') + ' 
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
				AND (''' + @FirstName + ''' = '''' OR ''' + @FirstName + ''' IS NULL OR Address_Book.First_Name LIKE ''%' + @FirstName + '%'')
				AND (''' + @LastName + ''' = '''' OR ''' + @LastName + ''' IS NULL OR Address_Book.Last_Name LIKE ''%' + @LastName + '%'')
				AND Intelledox_User.Business_Unit_GUID = CONVERT(uniqueidentifier, ''' + CONVERT(nvarchar(50), @BusinessUnitGUID) + ''')
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
			' + IsNull('PIVOT (MAX(Custom_Value) FOR CustomFieldTitle IN (' + @ColNames + ')) AS PivotedData', '') + 
			' ORDER BY Username';
		
	EXECUTE sp_executesql @SQL;
 
	SET @ErrorCode = @@error;
GO

