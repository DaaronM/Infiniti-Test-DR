/*
** Database Update package 8.0.0.5
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0.5');
go

--2036
ALTER TABLE Business_Unit
	ADD		SamlEnabled bit not null default (0),
			SamlCertificate nvarchar(max), 
			SamlCertificateType int not null default (0), 
			SamlCreateUsers bit not null default (0), 
			SamlIssuer nvarchar(255), 
			SamlLoginUrl nvarchar(1500), 
			SamlLogoutUrl nvarchar(1500),
			SamlLastLoginFail nvarchar(max)
GO
ALTER procedure [dbo].[spTenant_UpdateBusinessUnit]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(200),
	@SubscriptionType int,
	@ExpiryDate datetime,
	@TenantFee money,
	@DefaultLanguage nvarchar(10),
	@UserFee money,
	@SamlEnabled bit, 
	@SamlCertificate nvarchar(max), 
	@SamlCertificateType int, 
	@SamlCreateUsers bit, 
	@SamlIssuer nvarchar(255), 
	@SamlLoginUrl nvarchar(1500), 
	@SamlLogoutUrl nvarchar(1500),
	@SamlLastLoginFail nvarchar(max)
AS
	UPDATE	Business_Unit
	SET		Name = @Name,
			SubscriptionType = @SubscriptionType,
			ExpiryDate = @ExpiryDate,
			TenantFee = @TenantFee,
			DefaultLanguage = @DefaultLanguage,
			UserFee = @UserFee,
			SamlEnabled = @SamlEnabled,
			SamlCertificate = @SamlCertificate,
			SamlCertificateType = @SamlCertificateType, 
			SamlCreateUsers = @SamlCreateUsers, 
			SamlIssuer = @SamlIssuer, 
			SamlLoginUrl = @SamlLoginUrl, 
			SamlLogoutUrl = @SamlLogoutUrl,
			SamlLastLoginFail = @SamlLastLoginFail
	WHERE	Business_Unit_Guid = @BusinessUnitGuid;
GO
ALTER procedure [dbo].[spTenant_BusinessUnitList]
	@BusinessUnitGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	IF (@BusinessUnitGuid IS NULL)
	BEGIN
		SELECT	*
		FROM	Business_Unit;
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Business_Unit
		WHERE	Business_Unit_Guid = @BusinessUnitGuid;
	END

	set @errorcode = @@error;
GO

--2037

CREATE TABLE [dbo].[Action_Output](
	[ActionTypeID] [uniqueidentifier] NOT NULL,
	[ActionOutputID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_Action_Output] PRIMARY KEY CLUSTERED 
(
	[ActionOutputID] ASC
)
)

GO


CREATE PROCEDURE [dbo].[spRouting_ActionOutputList]
	@ActionTypeId uniqueidentifier
AS
	SELECT	*
	FROM	Action_Output
	WHERE	ActionTypeId = @ActionTypeId
	ORDER BY Name;


GO


CREATE PROCEDURE [dbo].[spRouting_RegisterActionOutput]
	@ActionTypeId uniqueidentifier,
	@ActionOutputId uniqueidentifier,
	@Name nvarchar(255)
AS
	IF NOT EXISTS(SELECT * 
		FROM Action_Output 
		WHERE ActionTypeId = @ActionTypeId 
			AND ActionOutputId = @ActionOutputId)
	BEGIN
		INSERT INTO Action_Output(ActionTypeId, ActionOutputId, Name)
		VALUES	(@ActionTypeId, @ActionOutputId, @Name);
	END
GO

DROP TABLE [dbo].[Routing_Output];
GO

DROP PROCEDURE [dbo].[spRouting_RouterOutputList];
GO

DROP PROCEDURE [dbo].[spRouting_RegisterRouterOutput];
GO

