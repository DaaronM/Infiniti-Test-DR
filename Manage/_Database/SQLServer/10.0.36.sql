truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.36');
GO

UPDATE [Intelledox_User]
SET [Language] = 'zh-Hans'
WHERE [Language] = 'zh-CN'
GO

UPDATE [Intelledox_User]
SET [Language] = 'zh-Hant'
WHERE [Language] = 'zh-TW'
GO

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'STORE_LOCATION','Whether to request and store location data when analytics module is attached', '0'
FROM Business_Unit bu
GO
