truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.1.17');
GO

-- add new store location data option
INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'Whether to request and store location data when analytics module is attached', '0'
FROM Business_Unit bu WHERE bu.Business_Unit_GUID NOT IN (
	SELECT BusinessUnitGuid from Global_Options where OptionCode = 'STORE_LOCATION'
)
GO
