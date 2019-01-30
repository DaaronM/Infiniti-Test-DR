/*
** Database Update package 8.2.3.0
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.3.0');
go


/* Users in groups view */

CREATE VIEW [dbo].[vwUsersInGroups]
AS
SELECT      ug.Name as GroupName, ug.Group_Guid,
			u.UserName as Username, u.User_Guid, u.Business_unit_Guid,
			ab.Full_Name as FullName, ab.First_Name, ab.Last_Name, ab.Prefix
FROM	    User_Group_Subscription ugs
LEFT JOIN	User_Group ug  ON ugs.GroupGuid = ug.Group_Guid
LEFT JOIN   Intelledox_User u ON ugs.UserGuid = u.User_Guid
LEFT JOIN	Address_Book ab on ab.Address_ID = u.Address_ID

GO

CREATE TABLE [dbo].[EscalationProperties](
			 [Id] [uniqueidentifier] NOT NULL,
			 [EscalationId] [uniqueidentifier] NOT NULL,
			 [EscalationTypeId] [uniqueidentifier] NOT NULL,
			 [EscalationInputValue] [nvarchar](max) NULL
CONSTRAINT [PK_ESCALATION_PROPERTY_ID]  PRIMARY KEY ( [Id] ))
GO


/* Escalation properties */

ALTER TABLE [dbo].[Workflow_Escalation]
ADD [EscalationTypeId] [uniqueidentifier] NOT NULL
CONSTRAINT ESCALATION_TYPE_DEFAULT DEFAULT '9B92350D-1673-473E-BAEF-219780CBB4BC'
GO


ALTER TABLE [dbo].[Routing_Type]
ADD SupportsRecurring bit NOT NULL DEFAULT(0)
GO

ALTER PROCEDURE [dbo].[spRouting_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ProviderType int,
	@RunForAllProjects bit,
	@SupportsRun bit,
	@SupportsUI bit,
	@SupportsRecurring bit = 0

AS
	IF NOT EXISTS(SELECT * FROM Routing_Type WHERE RoutingTypeId = @id)
	BEGIN
		INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription, ProviderType, RunForAllProjects, SupportsRun, SupportsUI, SupportsRecurring)
		VALUES	(@id, @Description, @ProviderType, @RunForAllProjects, @SupportsRun, @SupportsUI, @SupportsRecurring);
	END

GO


CREATE PROCEDURE [dbo].[spRouting_InsertEscalationProperty]
	@EscalationId uniqueidentifier,
	@EscalationTypeId uniqueidentifier,
	@EscalationInputValue nvarchar(max)
AS
	INSERT INTO EscalationProperties(Id, EscalationId, EscalationTypeId, EscalationInputValue)
	VALUES	(NewID(), @EscalationId, @EscalationTypeId, @EscalationInputValue);

GO

CREATE PROCEDURE [dbo].[spRouting_UpdateEscalationProperty]
	@EscalationId uniqueidentifier,
	@EscalationTypeId uniqueidentifier,
	@EscalationInputValue nvarchar(max)
AS
	UPDATE EscalationProperties
	SET	   EscalationInputValue = @EscalationInputValue
	WHERE  EscalationId = @EscalationId AND EscalationTypeId = @EscalationTypeId;

GO

CREATE PROCEDURE [dbo].[spRouting_DeleteEscalationProperties]
	@EscalationId uniqueidentifier
AS
	DELETE FROM EscalationProperties
	WHERE EscalationId = @EscalationId
GO

CREATE PROCEDURE [dbo].[spRouting_GetEscalationProperties]
	@EscalationId uniqueidentifier
AS
	SELECT	*
	FROM	EscalationProperties
	WHERE	EscalationProperties.EscalationId = @EscalationId

GO


/* Removed escalation as it was showing each escalation in the view */
ALTER VIEW [dbo].[vwWorkflowHistory]
AS
SELECT      dbo.ActionList.ActionListId, dbo.ActionList.ProjectGroupGuid, dbo.ActionList.CreatorGuid, dbo.ActionListState.ActionListStateId, 
            dbo.ActionListState.StateGuid, dbo.ActionListState.StateName, dbo.ActionListState.PreviousActionListStateId, 
            dbo.ActionListState.Comment, dbo.ActionListState.AnswerFileXml, dbo.ActionListState.AssignedGuid, dbo.ActionListState.AssignedType, 
            dbo.ActionListState.DateCreatedUtc, dbo.ActionListState.DateUpdatedUtc, dbo.ActionListState.AssignedByGuid, 
            dbo.ActionListState.LockedByUserGuid, 
            dbo.ActionListState.IsComplete, dbo.ActionListState.AllowReassign, dbo.ActionListState.RestrictToGroupGuid, dbo.ActionListState.IsAborted,
			u.UserName as AssignedBy, ab.Full_Name as AssignedByFullName,
			u2.UserName as AssignedTo, ab2.Full_Name as AssignedToFullName,
			ug.Name as AssignedGroupName,
			u.Business_Unit_GUID,
			case when dbo.ActionListState.AssignedType = 0 then dbo.ActionListState.AssignedGuid
			end as AssignedToUserGuid,
			case when dbo.ActionListState.AssignedType = 1 then dbo.ActionListState.AssignedGuid
			end as AssignedToGroupGuid
FROM        dbo.ActionList INNER JOIN
            dbo.ActionListState ON dbo.ActionList.ActionListId = dbo.ActionListState.ActionListId
LEFT JOIN	Intelledox_User u on u.User_Guid = AssignedByGuid
LEFT JOIN	Address_Book ab on ab.Address_ID = u.Address_ID
LEFT JOIN	Intelledox_User u2 on u2.User_Guid = AssignedGuid
LEFT JOIN	Address_Book ab2 on ab2.Address_ID = u2.Address_ID
LEFT JOIN   User_Group ug on ug.Group_Guid = AssignedGuid

GO

/* Migrate data from Workflow Escalation */
/* Subject */
INSERT INTO  [dbo].[EscalationProperties]([Id]
			,[EscalationId]
			,[EscalationTypeId]
			,[EscalationInputValue])
SELECT		 NewId()
			,[EscalationId]
			,'78587050-bc9d-4f5d-a92a-039ddf3f6b77'
			,[EscalateEmailSubject]
FROM		 [Workflow_Escalation]
WHERE		 [EscalateEmailSubject] IS NOT NULL
			 AND [EscalateOnUtc] IS NOT NULL

GO

/* Body */
INSERT INTO  [dbo].[EscalationProperties]([Id]
			,[EscalationId]
			,[EscalationTypeId]
			,[EscalationInputValue])
SELECT		 NewId()
			,[EscalationId]
			,'bf1973a6-3ad2-4fb2-ab6f-23474843f921'
			,[EscalateEmailBody]
FROM		 [Workflow_Escalation]
WHERE		 [EscalateEmailBody] IS NOT NULL
			 AND [EscalateOnUtc] IS NOT NULL

GO

/* CC */
INSERT INTO  [dbo].[EscalationProperties]([Id]
			,[EscalationId]
			,[EscalationTypeId]
			,[EscalationInputValue])
SELECT		 NewId()
			,[EscalationId]
			,'844838b2-99ea-46a2-81df-b40b3177d3f6'
			,[EscalateEmailCC]
FROM		 [Workflow_Escalation]
WHERE		 [EscalateEmailCC] IS NOT NULL
			 AND [EscalateOnUtc] IS NOT NULL

GO

/* Send To Assignee */
INSERT INTO  [dbo].[EscalationProperties]([Id]
			,[EscalationId]
			,[EscalationTypeId]
			,[EscalationInputValue])
SELECT		 NewId()
			,[EscalationId]
			,'3c5f829f-b631-45ce-8956-a839157c3bb6'
			,[SendToAssignee]
FROM		 [Workflow_Escalation]
WHERE		 [SendToAssignee] IS NOT NULL
			 AND [EscalateOnUtc] IS NOT NULL
			 

GO



CREATE PROCEDURE spWorkflowEscalationCleanup(
	@TaskListStateId uniqueidentifier,
	@ClearCompleteOnly bit = 1
	)
AS
BEGIN
	
	IF (SELECT object_id('TempDB..#State')) IS NOT NULL
	BEGIN
		DROP TABLE #State
	END

	IF (SELECT object_id('TempDB..#Escalation')) IS NOT NULL
	BEGIN
		DROP TABLE #Escalation
	END

	/* Find the taskid so we can fetch all the other states */
	declare @taskID uniqueidentifier 
	set @taskID = (Select ActionListId from actionliststate where actionliststateid = @taskListStateId)

	/* Create a blank table so we can insert conditionally from the if statement below */
	SELECT * INTO #State FROM ActionListState WHERE (1=0)

	IF (@ClearCompleteOnly = 1)
		BEGIN
			INSERT INTO #State SELECT * FROM ActionListState WHERE actionListId = @taskID and iscomplete=1
		END
	ELSE
		BEGIN
			INSERT INTO #State SELECT * FROM ActionListState WHERE actionListId = @taskID
		END

	SELECT we.RecurrenceId, we.EscalationId, we.ActionListStateId INTO #Escalation FROM Workflow_Escalation we
	join #State tt ON we.ActionListStateId = tt.ActionListStateId

	DROP TABLE #State

	DELETE rp
	FROM RecurrencePattern rp
	JOIN #Escalation ON rp.RecurrencePatternId = #Escalation.RecurrenceId

	DELETE ep
	FROM EscalationProperties ep
	JOIN #Escalation ON ep.EscalationId = #Escalation.Escalationid

	DELETE we
	FROM Workflow_Escalation we
	JOIN #Escalation ON we.EscalationId = #Escalation.EscalationId

	DROP TABLE #Escalation

END
GO

ALTER TABLE [Workflow_Escalation] DROP CONSTRAINT [DF_SendToAssignee]
GO

ALTER TABLE [Workflow_Escalation]
DROP COLUMN [EscalateEmailSubject], [SendToAssignee], [EscalateEmailCC], [EscalateEmailBody]

GO


/* Email individual members */

ALTER TABLE Address_Book
ADD Email_Individual_Members bit NOT NULL
CONSTRAINT AB_Default_Email_Members DEFAULT 0
GO

ALTER procedure [dbo].[spAddBk_UpdateAddress]
	@AddressID int,
	@AddressTypeID int,
	@Reference nvarchar(50),
	@Prefix nvarchar(50),
	@Title nvarchar(50),
	@FullName nvarchar(100),
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@Salutation nvarchar(50),
	@Organisation nvarchar(100),
	@EmailAddress nvarchar(50),
	@FaxNumber nvarchar(50),
	@PhoneNumber nvarchar(50),
	@StreetAddress1 nvarchar(50),
	@StreetAddress2 nvarchar(50),
	@StreetSuburb nvarchar(50),
	@StreetState nvarchar(50),
	@StreetPostcode nvarchar(50),
	@StreetCountry nvarchar(50),
	@PostalAddress1 nvarchar(50),
	@PostalAddress2 nvarchar(50),
	@PostalSuburb nvarchar(50),
	@PostalState nvarchar(50),
	@PostalPostcode nvarchar(50),
	@PostalCountry nvarchar(50),
	@SubscribeUser int,
	@EmailIndividualMembers bit = 0,
	@NewID int = 0 output,
	@ErrorCode int = 0 output
AS
	--This may be an insert or an update, depending on AddressID.
	IF @AddressID = 0
	begin
		INSERT INTO Address_Book (addresstype_id, address_reference,
			prefix, first_name, last_name, full_name, salutation_name, title,
			organisation_name, phone_number, fax_number, email_address,
			street_address_1, street_address_2, street_address_suburb, street_address_state,
			street_address_postcode, street_address_country, postal_address_1, postal_address_2,
			postal_address_suburb, postal_address_state, postal_address_postcode, postal_address_country, email_individual_members)
		VALUES (@AddressTypeID, @Reference,
			@Prefix, @FirstName, @LastName, @FullName, @Salutation, @Title,
			@Organisation, @PhoneNumber, @FaxNumber, @EmailAddress,
			@StreetAddress1, @StreetAddress2, @StreetSuburb, @StreetState,
			@StreetPostcode, @StreetCountry, @PostalAddress1, @PostalAddress2,
			@PostalSuburb, @PostalState, @PostalPostcode, @PostalCountry, @EmailIndividualMembers);

		SELECT @NewID = @@Identity;
		SET @AddressID = @NewID;
	end
	ELSE
	begin
		UPDATE Address_Book
		SET Addresstype_ID = @AddressTypeID,
			Address_Reference = @Reference, Prefix = @Prefix, First_Name = @FirstName,
			Last_Name = @LastName, Full_Name = @FullName, Salutation_Name = @Salutation,
			Title = @Title, Organisation_Name = @Organisation, Phone_number = @PhoneNumber,
			Fax_number = @FaxNumber, Email_Address = @EmailAddress,
			Street_Address_1 = @StreetAddress1, Street_Address_2 = @StreetAddress2,
			Street_Address_Suburb = @StreetSuburb, Street_Address_State = @StreetState,
			Street_Address_Postcode = @StreetPostcode, Street_Address_Country = @StreetCountry,
			Postal_Address_1 = @PostalAddress1, Postal_Address_2 = @PostalAddress2,
			Postal_Address_Suburb = @PostalSuburb, Postal_Address_State = @PostalState,
			Postal_Address_Postcode = @PostalPostcode, Postal_Address_Country = @PostalCountry, Email_Individual_Members = @EmailIndividualMembers
		WHERE Address_ID = @AddressID;
	end
		
	IF (@SubscribeUser > 0) AND (@SubscribeUser IS NOT NULL)
		exec spAddBk_SubscribeUserAddress @SubscribeUser, @AddressID, @ErrorCode output;

	set @errorcode = @@error;


	GO


