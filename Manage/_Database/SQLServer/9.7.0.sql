truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.7.0');
go
IF DATABASE_PRINCIPAL_ID('db_executor') IS NULL
BEGIN
	CREATE ROLE db_executor
END
GRANT EXECUTE TO db_executor
GO
DELETE ph
FROM Password_History as ph
INNER JOIN
(
	SELECT User_Guid, DateCreatedUtc
	FROM Password_History
	GROUP BY User_Guid, DateCreatedUtc
	HAVING COUNT(*) > 1
) phGroup
ON ph.User_Guid = phGroup.User_Guid AND ph.DateCreatedUtc = phGroup.DateCreatedUtc
GO
CREATE TABLE [dbo].[TmpPassword_History](
	[User_Guid] [uniqueidentifier] NOT NULL,
	[DateCreatedUtc] [datetime] NOT NULL DEFAULT GETUTCDATE(),
	[pwdhash] [varchar](1000) NOT NULL,
	 CONSTRAINT [PK_Password_HistoryUD] PRIMARY KEY CLUSTERED 
	(
		[User_Guid] ASC,
		[DateCreatedUtc] ASC
	)
)
GO
INSERT INTO [TmpPassword_History]([User_Guid], [DateCreatedUtc], [pwdhash])
SELECT [User_Guid], [DateCreatedUtc], [pwdhash]
FROM [Password_History]
ORDER BY [User_Guid], [DateCreatedUtc]
GO
DROP TABLE Password_History
GO
exec sp_rename 'dbo.TmpPassword_History', 'Password_History'
GO
ALTER PROCEDURE [dbo].[spUser_AddToPasswordHistory]
	@BusinessUnitGuid uniqueidentifier,
	@UserGuid uniqueidentifier,
	@PwdHash varchar(1000)
AS
BEGIN
	DECLARE @HistoryLimit integer

	SET @HistoryLimit = (SELECT Global_Options.OptionValue 
						FROM Global_Options 
						WHERE  Global_Options.BusinessUnitGuid = @BusinessUnitGuid
							AND Global_Options.OptionCode = 'PASSWORD_HISTORY_COUNT')

	IF (@HistoryLimit > 0)
	BEGIN
		INSERT INTO [Password_History] (User_Guid, pwdhash)
		VALUES (@UserGuid, @PwdHash)

		DELETE FROM Password_History
		WHERE DateCreatedUtc < 
				(SELECT MIN(DateCreatedUtc)
				FROM
						(SELECT TOP (@HistoryLimit) DateCreatedUtc 
						FROM Password_History 
						WHERE User_Guid = @UserGuid
						ORDER BY DateCreatedUtc DESC) TopNDates
				)
			AND User_Guid = @UserGuid;
	END
END
GO
CREATE PROCEDURE [dbo].[spUsers_UsersPaging]
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@Firstname nvarchar(50) = '',
	@Lastname nvarchar(50) = '',
	@StartRow int,
	@MaximumRows int
AS
BEGIN
	if @UserGroupID = 0	--all user groups
	begin
		if @Username = '' AND @Firstname = '' AND @Lastname = '' AND @ShowActive = 0 
		begin
			select *
			from (
				select	a.*, d.[First_Name], d.[Last_Name], ROW_NUMBER() OVER (ORDER BY a.[Username]) AS RowRank
				from	Intelledox_User a
					left join Address_Book d on a.Address_ID = d.Address_ID
				where	a.Business_Unit_GUID = @BusinessUnitGUID
				) as RankedUsers
			WHERE RowRank > @StartRow AND RowRank <= (@StartRow + @MaximumRows)
		end
		else
		begin
			select *
			from (
				select	a.*, d.[First_Name], d.[Last_Name], ROW_NUMBER() OVER (ORDER BY a.[Username]) AS RowRank
				from	Intelledox_User a
					left join Address_Book d on a.Address_ID = d.Address_ID
				where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
					AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
					AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				) as RankedUsers
			WHERE RowRank > @StartRow AND RowRank <= (@StartRow + @MaximumRows)
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select *
			from (
				select	a.*,  d.[First_Name], d.[Last_Name], ROW_NUMBER() OVER (ORDER BY a.[Username]) AS RowRank
				from	Intelledox_User a
					left join Address_Book d on a.Address_Id = d.Address_id
				where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
					AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
					AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
					AND	a.User_Guid not in (
							select a.userGuid
							from user_group_subscription a 
							inner join user_Group b on a.GroupGuid = b.Group_Guid
						)
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				) as RankedUsers
			WHERE RowRank > @StartRow AND RowRank <= (@StartRow + @MaximumRows)
		end
		else			--users in specified user group
		begin
			select *
			from (
				select	a.*,  d.[First_Name], d.[Last_Name], ROW_NUMBER() OVER (ORDER BY a.[Username]) AS RowRank
				from	Intelledox_User a
					inner join User_Group_Subscription c on a.User_Guid = c.UserGuid
					left join Address_Book d on a.Address_Id = d.Address_id
				where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
					AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
					AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
					AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				) as RankedUsers
			WHERE RowRank > @StartRow AND RowRank <= (@StartRow + @MaximumRows)
		end
	end
END
GO
CREATE PROCEDURE [dbo].[spUsers_UserGroupByUserCount]
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@Firstname nvarchar(50) = '',
	@Lastname nvarchar(50) = ''
AS
BEGIN
	if @UserGroupID = 0	--all user groups
	begin
		if @Username = '' AND @Firstname = '' AND @Lastname = '' AND @ShowActive = 0 
		begin
			select	COUNT(*)
			from	Intelledox_User a
			where	a.Business_Unit_GUID = @BusinessUnitGUID
		end
		else
		begin
			select	COUNT(*)
			from	Intelledox_User a
				left join Address_Book d on a.Address_ID = d.Address_ID
			where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
				AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
				AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select	COUNT(*)
			from	Intelledox_User a
				left join Address_Book d on a.Address_Id = d.Address_id
			where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
				AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
				AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
				AND	a.User_Guid not in (
						select a.userGuid
						from user_group_subscription a 
						inner join user_Group b on a.GroupGuid = b.Group_Guid
					)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
		end
		else			--users in specified user group
		begin
			select	COUNT(*)
			from	Intelledox_User a
				inner join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join Address_Book d on a.Address_Id = d.Address_id
			where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
				AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
				AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
				AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
		end
	end
END
GO
CREATE NONCLUSTERED INDEX IX_Intelledox_User_AddressId ON dbo.Intelledox_User
	(
	Address_ID
	)
GO
ALTER procedure [dbo].[spProject_GetInUseProjectLicenseCount]
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

	SELECT COUNT(DISTINCT Template_Guid) as Count, Intelledox_User.IsGuest
	FROM Template_Group
		INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
		INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
		INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE [Disabled] = 0
		AND Business_Unit_GUID = @BusinessUnitGuid
	GROUP BY Intelledox_User.IsGuest;
END
GO
ALTER PROCEDURE [dbo].[spUsers_UserCount]
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT COUNT(CASE WHEN IsGuest = 0 AND Disabled = 0 THEN 1 ELSE 0 END) 
	FROM Intelledox_User
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END
GO
CREATE PROCEDURE [dbo].[spUsers_UserCheckByFolder]
	@FolderGuid uniqueidentifier,
	@Anonymous bit
AS
BEGIN
	SELECT TOP 1 1
	FROM Folder_Group
		INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
		INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE Folder_Group.FolderGuid = @FolderGuid
		AND Intelledox_User.IsGuest = @Anonymous
		AND Intelledox_User.[Disabled] = 0;
END
GO
CREATE PROCEDURE [dbo].[spUsers_UserCheckByGroup]
	@GroupGuid uniqueidentifier,
	@Anonymous bit
AS
BEGIN
	SELECT TOP 1 1
	FROM User_Group_Subscription
		INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE GroupGuid = @GroupGuid
		AND Intelledox_User.IsGuest = @Anonymous
		AND Intelledox_User.[Disabled] = 0;
END
GO
CREATE PROCEDURE [dbo].[spUsers_UserCheckByProject]
	@ProjectGuid uniqueidentifier,
	@Anonymous bit
AS
BEGIN
	SELECT TOP 1 1
	FROM Template_Group
		INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
		INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
		INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE Template_Group.Template_Guid = @ProjectGuid
		AND Intelledox_User.IsGuest = @Anonymous
		AND Intelledox_User.[Disabled] = 0;
END
GO
DROP PROCEDURE [dbo].[spUsers_UserCountByFolder]
DROP PROCEDURE [dbo].[spUsers_UserCountByGroup]
DROP PROCEDURE [dbo].[spUsers_UserCountByProject]
GO
ALTER PROCEDURE [dbo].[spUsers_UserGuestUser]
	@BusinessUnitGuid uniqueidentifier
AS
	SELECT	TOP 1 *
	FROM	Intelledox_User
	WHERE	Business_Unit_GUID = @BusinessUnitGuid 
		AND IsGuest = 1;
GO
ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
	@ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, t.[Name] as Template_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, a.Template_Guid, a.Layout_Guid,
			a.Template_Version, a.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
			a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
			a.HideNavigationPane, a.ShowFormActivity, a.MatchProjectVersion,
			a.AllowRestart, a.OfflineDataSources, a.LogPageTransition,
			a.AllowSave, a.Folder_Guid
    FROM	Template_Group a
			INNER JOIN Template t on a.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
ALTER procedure [dbo].[spProject_ProjectByName]
	@ProjectName nvarchar(100),
	@BusinessUnitGuid uniqueidentifier,
	@PublishableOnly bit = 0
as
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
			LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	a.Business_Unit_GUID = @BusinessUnitGuid
			AND a.Name = @ProjectName
			AND (
				(@PublishableOnly = 1 AND Template_Type_ID IN (1,3))
				OR @PublishableOnly = 0
			)
GO

ALTER PROCEDURE [dbo].[spProjectGroup_FolderListSearch]
	@UserGuid uniqueidentifier,
	@SearchTerm nvarchar(50)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;

	SELECT	f.Folder_Name, tg.Template_Group_ID,
			tg.HelpText as TemplateGroup_HelpText, t.[Name] as Template_Name, 
			tg.Template_Group_Guid, tg.FeatureFlags
	FROM	Folder f
			INNER JOIN Template_Group tg on f.Folder_Guid = tg.Folder_Guid
			INNER JOIN Template t on tg.Template_Guid = t.Template_Guid
	WHERE	f.Business_Unit_GUID = @BusinessUnitGUID
			AND f.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
				WHERE	User_Group_Subscription.UserGuid = @UserGuid
				)
			AND (f.Folder_Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchTerm + '%') COLLATE Latin1_General_CI_AI
			     OR t.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchTerm + '%') COLLATE Latin1_General_CI_AI
			     OR tg.HelpText COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchTerm + '%') COLLATE Latin1_General_CI_AI)
			AND (tg.EnforcePublishPeriod = 0 
				OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
					AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
	ORDER BY f.Folder_Name, t.[Name]

GO
