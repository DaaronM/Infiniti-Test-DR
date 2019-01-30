/*
** Database Update package 8.0.0.6
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0.6');
go

--2038

DROP TABLE [dbo].[ProviderSettings_ElementType];
GO

DROP TABLE [dbo].[ProviderSettings_Type];
GO

DROP PROCEDURE [dbo].[spProviderSettings_ElementTypeList];
GO

DROP PROCEDURE [dbo].[spProviderSettings_RegisterElementType];
GO

DROP PROCEDURE [dbo].[spProviderSettings_RegisterSettingsType];
GO

DROP PROCEDURE [dbo].[spProviderSettings_TypeList];
GO

DROP PROCEDURE [dbo].[spProviderSettings_UpdateElementTypeValue];
GO

CREATE TABLE [dbo].[ConnectorSettings_ElementType](
	[ConnectorSettingsElementTypeId] [uniqueidentifier] NOT NULL,
	[ConnectorSettingsTypeId] [uniqueidentifier] NOT NULL,
	[DescriptionDefault] [nvarchar](255) NULL,
	[Encrypt] [bit] NULL,
	[SortOrder] [numeric](18, 0) NULL,
	[ElementValue] [nvarchar](max) NULL,
 CONSTRAINT [PK_ConnectorSettings_ElementType] PRIMARY KEY CLUSTERED 
(
	[ConnectorSettingsElementTypeId] ASC
)
)

GO

CREATE TABLE [dbo].[ConnectorSettings_Type](
	[ConnectorSettingsTypeId] [uniqueidentifier] NOT NULL,
	[ConnectorSettingsDescription] [nvarchar](255) NULL,
 CONSTRAINT [PK_ConnectorSettings_Type] PRIMARY KEY CLUSTERED 
(
	[ConnectorSettingsTypeId] ASC
)
)

GO

CREATE PROCEDURE [dbo].[spConnectorSettings_ElementTypeList] 
	-- Add the parameters for the stored procedure here
	@ConnectorSettingsTypeId uniqueidentifier
AS
BEGIN
	SELECT * 
	FROM ConnectorSettings_ElementType
	WHERE ConnectorSettingsTypeId = @ConnectorSettingsTypeId
	ORDER BY SortOrder, DescriptionDefault
END
GO

CREATE PROCEDURE [dbo].[spConnectorSettings_RegisterElementType]
	@ConnectorSettingsElementTypeId uniqueidentifier,
	@ConnectorSettingsTypeId uniqueidentifier,
	@Description nvarchar(255),
	@Encrypt bit,
	@SortOrder int,
	@ElementValue nvarchar(max) = ''
AS
	IF NOT EXISTS(SELECT * FROM ConnectorSettings_ElementType WHERE ConnectorSettingsElementTypeId = @ConnectorSettingsElementTypeId AND ConnectorSettingsTypeId = @ConnectorSettingsTypeId)
	BEGIN
		INSERT INTO ConnectorSettings_ElementType(ConnectorSettingsElementTypeId,ConnectorSettingsTypeId,DescriptionDefault,Encrypt,SortOrder,ElementValue)
		VALUES (@ConnectorSettingsElementTypeId,@ConnectorSettingsTypeId,@Description,@Encrypt,@SortOrder,@ElementValue);
	END

GO

CREATE PROCEDURE [dbo].[spConnectorSettings_RegisterSettingsType]
	@Id uniqueidentifier,
	@Description nvarchar(255)
AS
	IF NOT EXISTS(SELECT * FROM  ConnectorSettings_Type WHERE ConnectorSettingsTypeId = @id)
	BEGIN
		INSERT INTO ConnectorSettings_Type(ConnectorSettingsTypeId, ConnectorSettingsDescription)
		VALUES	(@id, @Description);
	END


GO

CREATE PROCEDURE [dbo].[spConnectorSettings_TypeList]
	
AS
BEGIN
	SELECT * 
	FROM ConnectorSettings_Type
	ORDER BY ConnectorSettingsDescription
END


GO


CREATE PROCEDURE [dbo].[spConnectorSettings_UpdateElementTypeValue]
	-- Add the parameters for the stored procedure here
	@ConnectorSettingsElementTypeId uniqueidentifier,
	@ElementValue nvarchar(max)
AS
BEGIN
	UPDATE ConnectorSettings_ElementType
	SET ElementValue = @ElementValue
	WHERE ConnectorSettingsElementTypeId = @ConnectorSettingsElementTypeId
END

GO

--2039
ALTER TABLE Business_Unit
	ADD SamlManageEntityId nvarchar(1500) null,
		SamlProduceEntityId nvarchar(1500) null
GO
UPDATE	Business_Unit
SET		SamlManageEntityId = 'Manage',
		SamlProduceEntityId = 'Produce'
WHERE	SamlEnabled = 1;
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
	@SamlManageEntityId nvarchar(1500),
	@SamlProduceEntityId nvarchar(1500),
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
			SamlManageEntityId = @SamlManageEntityId,
			SamlProduceEntityId = @SamlProduceEntityId,
			SamlLastLoginFail = @SamlLastLoginFail
	WHERE	Business_Unit_Guid = @BusinessUnitGuid;
GO

