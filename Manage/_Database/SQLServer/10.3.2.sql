truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.3.2');
GO

INSERT INTO [dbo].[Global_Options] ([OptionCode], [OptionDescription], [OptionValue], [BusinessUnitGuid]) 
SELECT N'DOCUSIGN_PRODUCTION_ENVIRONMENT', N'DocuSign Production Environment', N'False', Business_Unit_GUID
FROM Business_Unit;
GO

INSERT INTO [dbo].[Global_Options] ([OptionCode], [OptionDescription], [OptionValue], [BusinessUnitGuid]) 
SELECT N'DOCUSIGN_LOG_MODE', N'DocuSign Log Mode', N'False', Business_Unit_GUID
FROM Business_Unit;
GO

INSERT INTO [dbo].[Global_Options] ([OptionCode], [OptionDescription], [OptionValue], [BusinessUnitGuid]) 
SELECT N'DOCUSIGN_ADMIN_API_USERNAME', N'DocuSign Admin API Username', N'', Business_Unit_GUID
FROM Business_Unit;
GO

INSERT INTO [dbo].[Global_Options] ([OptionCode], [OptionDescription], [OptionValue], [BusinessUnitGuid]) 
SELECT N'DOCUSIGN_INTEGRATOR_KEY', N'DocuSign Integrator Key', N'', Business_Unit_GUID
FROM Business_Unit;
GO

INSERT INTO [dbo].[Global_Options] ([OptionCode], [OptionDescription], [OptionValue], [BusinessUnitGuid]) 
SELECT N'DOCUSIGN_EMBEDDED_SIGNING_URL', N'DocuSign Embedded Signing Return Url', N'', Business_Unit_GUID
FROM Business_Unit;
GO

INSERT INTO [dbo].[Global_Options] ([OptionCode], [OptionDescription], [OptionValue], [BusinessUnitGuid]) 
SELECT N'DOCUSIGN_RSA_PRIVATE_KEY', N'DocuSign RSA Private Key', N'', Business_Unit_GUID
FROM Business_Unit;
GO
