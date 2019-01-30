/*
** Database Update package 7.2.16
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('7.2.16');
go

--2015
CREATE procedure [dbo].[spUsers_UserData]
	@BusinessUnitGUID nvarchar(50),
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@ErrorCode int = 0 output
as
	SET NOCOUNT ON;

	DECLARE @ColNames nvarchar(MAX);
	
	-- Find the Custom_Fields
	-- Will look like "[CustomField1],[CustomField2],[Custom_Field."
	SET @ColNames = '[' + (
		SELECT Title + '],[' 
		FROM Custom_Field 
		WHERE Validation_Type <> 3
		FOR XML PATH('')) ;
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
				LEFT JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID]
				LEFT JOIN User_Group ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
				LEFT JOIN Address_Book ON Intelledox_User.[User_ID] = Address_Book.[User_ID] 
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
 
	SET @ErrorCode = @@error
GO

--2016
ALTER procedure [dbo].[spUsers_UserGroupByUser]
	@UserID int,
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@UserGuid uniqueidentifier = null,
	@ShowActive int = 0,
	@ErrorCode int = 0 output
as
/* MOD HISTORY
VERSION	DATE		DEVELOPER		DESCRIPTION
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
3.2.2		14-dec-04	chrisg			Allow filtering on username and usergroupid (new parameters)
*/
	if @UserGroupID = 0	--all user groups
	begin
		if @UserGuid is null
		begin
			if @UserID is null or @UserID = 0
			begin
				select	a.*, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				where	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
			else
			begin
				select	a.*, b.*, c.Default_Group, d.Full_Name, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
					left join User_Group b on c.User_Group_ID = b.User_Group_ID
					left join Address_Book d on a.[User_ID] = d.[User_ID]
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				where	(a.[User_ID] = @UserID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
		end
		else
		begin
			select	a.*, b.*, c.Default_Group, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
				left join User_Group b on c.User_Group_ID = b.User_Group_ID
				left join Address_Book d on a.[User_ID] = d.[User_ID]
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(User_Guid = @UserGuid)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select	a.*, b.*, c.Default_Group, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
				left join User_Group b on c.User_Group_ID = b.User_Group_ID
				left join Address_Book d on a.[User_ID] = d.[User_ID]
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
				AND	a.[User_ID] not in (
						select a.[user_id]
						from user_group_subscription a 
						inner join user_Group b on a.user_group_id = b.user_group_id
						where b.deleted = 0 or b.deleted is null
					)
				AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
		else			--users in specified user group
		begin
			select	a.*, b.*, c.Default_Group, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
				left join User_Group b on c.User_Group_ID = b.User_Group_ID
				left join Address_Book d on a.[User_ID] = d.[User_ID]
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
				AND	c.User_Group_ID = @UserGroupID
				AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end

	set @ErrorCode = @@error
GO

