truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.5.1');
go

ALTER PROCEDURE [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT d.Template_Group_ID, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid, l.DateTime_Start, l.Log_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
			INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
						INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND b.Name LIKE '%' + @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY l.DateTime_Start DESC;
GO

ALTER TABLE dbo.Intelledox_UserDeleted ADD
	User_ID int NULL
GO

ALTER procedure [dbo].[spUsers_RemoveUser]
	@UserGuid uniqueidentifier
AS
	SET NOCOUNT ON;

	DECLARE @UserId int;
	DECLARE @AddressId int;
	
	SELECT	@UserId = [User_Id], @AddressId = Address_ID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	-- In case a restored user has been re-deleted, clear the history item
	DELETE Intelledox_UserDeleted WHERE UserGuid = @UserGuid;

	INSERT INTO Intelledox_UserDeleted(UserGuid, Username, BusinessUnitGuid, FirstName, LastName, Email, User_ID)
	SELECT Intelledox_User.User_Guid, Intelledox_User.Username, Intelledox_User.Business_Unit_GUID,
			Address_Book.First_Name, Address_Book.Last_Name, Address_Book.Email_Address, @UserId
	FROM Intelledox_User
		LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
	WHERE Intelledox_User.User_Guid = @UserGuid;
	
	DELETE Address_Book WHERE Address_ID = @AddressId;
	DELETE User_Address_Book WHERE [User_Id] = @UserId;
	DELETE User_Group_Subscription WHERE UserGuid = @UserGuid;
	DELETE Intelledox_User WHERE User_Guid = @UserGuid;

GO

ALTER procedure [dbo].[spSync_UserIntoDeletedUser]
	@UserGuid uniqueidentifier,
	@Username nvarchar(256),
	@BusinessUnitGuid uniqueidentifier,
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@Email nvarchar(256),
	@UserID int
AS
	IF NOT EXISTS
		(Select UserGuid from Intelledox_UserDeleted where Intelledox_UserDeleted.UserGuid = @UserGuid
		Union 
		Select User_Guid from Intelledox_User where Intelledox_User.User_Guid = @UserGuid)
	BEGIN
		INSERT INTO Intelledox_UserDeleted(UserGuid, Username, BusinessUnitGuid, FirstName, LastName, Email, User_ID)
		VALUES(@UserGuid, @Username, @BusinessUnitGuid, @FirstName, @LastName, @Email, @UserID)
	END
GO

ALTER VIEW [dbo].[vwSubmissions]
AS

	SELECT	Template_Log.Log_Guid,
			Template.Template_Id,
			Template_Log.DateTime_Finish AS _Completion_Time_UTC,
			(SELECT Username FROM Intelledox_User WHERE User_ID = Template_Log.User_ID
				UNION
				SELECT Username FROM Intelledox_UserDeleted WHERE User_ID = Template_Log.User_ID)
			AS _Username,
			CASE WHEN Template_Log.CompletionState = 3 THEN 1 ELSE 0 END AS _Completed,
			CASE WHEN Template_Log.CompletionState = 2 THEN 1 ELSE 0 END AS _WorkflowInProgress,
			(SELECT TOP 1 LatestState.StateName
				FROM ActionListState LatestState
				WHERE LatestState.ActionListId = ActionListState.ActionListId
				ORDER BY LatestState.DateCreatedUtc DESC) AS _CurrentState
	FROM	Template_Log 
			INNER JOIN Template_Group ON Template_Group.Template_Group_Id = Template_Log.Template_Group_Id
			INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
			LEFT JOIN ActionListState ON Template_Log.ActionListStateId = ActionListState.ActionListStateId
	WHERE Template_Log.CompletionState = 3
		OR (Template_Log.CompletionState = 2
			AND Template_Log.DateTime_Finish IN (SELECT MAX(tl.DateTime_Finish)
				FROM Template_Log tl
					INNER JOIN ActionListState als On tl.ActionListStateId = als.ActionListStateId
						AND als.ActionListId = ActionListState.ActionListId))


GO
