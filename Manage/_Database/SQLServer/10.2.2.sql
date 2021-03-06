truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.2.2');
GO
DECLARE @BusinessUnitCount INT;

SET @BusinessUnitCount = (SELECT COUNT(*) FROM Business_Unit);

IF @BusinessUnitCount = 1
BEGIN
	UPDATE	Global_Options
	SET		OptionValue = CAST(Business_Unit.Business_Unit_GUID as NVARCHAR(MAX))
	FROM	Business_Unit
	WHERE	Global_Options.OptionCode = 'DEFAULT_TENANT'
END
GO
DECLARE @CommonProduceSite NVARCHAR(max)
DECLARE @CommonManageSite NVARCHAR(max)

SET @CommonProduceSite = (SELECT Top 1 OptionValue
	FROM   Global_Options
	WHERE OptionCode = 'PRODUCER_URL'
		AND BusinessUnitGuid = (SELECT OptionValue
								FROM Global_Options
								WHERE UPPER(OptionCode) = 'DEFAULT_TENANT'))

SET @CommonManageSite = (SELECT Top 1 OptionValue
	FROM   Global_Options
	WHERE OptionCode = 'DIRECTOR_URL'
		AND BusinessUnitGuid = (SELECT OptionValue
								FROM Global_Options
								WHERE UPPER(OptionCode) = 'DEFAULT_TENANT'))

INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'PRODUCER_URL','URL to the Produce application', @CommonProduceSite)

INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'DIRECTOR_URL','URL to the Manage application', @CommonManageSite)

UPDATE Global_Options
SET	OptionValue = ''
WHERE OptionCode = 'PRODUCER_URL'
	AND BusinessUnitGuid <> '00000000-0000-0000-0000-000000000000'
	AND OptionValue = @CommonProduceSite

UPDATE Global_Options
SET	OptionValue = ''
WHERE OptionCode = 'DIRECTOR_URL'
	AND BusinessUnitGuid <> '00000000-0000-0000-0000-000000000000'
	AND OptionValue = @CommonManageSite
GO
ALTER procedure [dbo].[spOptions_LoadOptions]
	@BusinessUnitGuid uniqueidentifier,
	@Code nvarchar(255)
as
	SELECT	*
	FROM	Global_Options
	where	@Code = optioncode
			AND BusinessUnitGuid = @BusinessUnitGuid;
GO
CREATE PROCEDURE [dbo].[spTenant_IdentifyBusinessUnitByUrl]
	@Url NVarChar(max)
AS
	SELECT	TOP 1 Business_Unit.*
	FROM	Business_Unit
			INNER JOIN Global_Options ON Business_Unit.Business_Unit_GUID = Global_Options.BusinessUnitGuid
	WHERE	(Global_Options.OptionCode = 'PRODUCER_URL'
			OR Global_Options.OptionCode = 'DIRECTOR_URL')
			AND OptionValue LIKE '%/' + @Url + '/%';
GO
