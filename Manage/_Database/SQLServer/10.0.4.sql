truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.4');
go

UPDATE Routing_ElementType
SET	ElementLimit = 0,
	IsKeyValue = 1
WHERE RoutingElementTypeId = 'F5187711-3DB5-4597-B454-E6D02234C510'
GO
UPDATE Routing_ElementType
SET	ElementTypeDescription = 'Custom Headers',
	IsKeyValue = 1
WHERE RoutingElementTypeId = '024B72CE-C203-44B6-84A3-E181EED5FCFE'
GO

IF NOT EXISTS(SELECT * FROM Global_Options WHERE OptionCode = 'DISALLOW_COMMON_PASSWORDS')
BEGIN
	INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
	SELECT bu.Business_Unit_GUID,'DISALLOW_COMMON_PASSWORDS','Must not belong in the common password denial list.', 'False'
	FROM Business_Unit bu
END
GO
