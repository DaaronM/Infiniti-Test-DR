/*
** Database Update package 8.0.1.1
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.1.1');
go

--2047
DELETE FROM EventLog
WHERE LevelId = 1
	AND DateTime < DateAdd(m, -6, GetDate())

DELETE FROM EventLog
WHERE Message = 'Database Upgrade 8.0.0.21 Completed'
	AND LogEventID NOT IN (
		select Min(LogEventID)
		FROM EventLog
		WHERE Message = 'Database Upgrade 8.0.0.21 Completed'
		)
GO


--2048
update Address_Book_Custom_Field
set Address_Book_Custom_Field.Custom_Value = 
	SUBSTRING(Address_Book_Custom_Field.Custom_Value, 7, 4) + '-' +
	SUBSTRING(Address_Book_Custom_Field.Custom_Value, 4, 2) + '-' +
	SUBSTRING(Address_Book_Custom_Field.Custom_Value, 1, 2)
from Custom_Field
	inner join Address_Book_Custom_Field on Custom_Field.Custom_Field_id = Address_Book_Custom_Field.Custom_Field_id
where Custom_Field.Validation_Type = 1
	and Address_Book_Custom_Field.Custom_Value like '__/__/____'

update Address_Book_Custom_Field
set Address_Book_Custom_Field.Custom_Value = 
	SUBSTRING(Address_Book_Custom_Field.Custom_Value, 6, 4) + '-' +
	SUBSTRING(Address_Book_Custom_Field.Custom_Value, 3, 2) + '-0' +
	SUBSTRING(Address_Book_Custom_Field.Custom_Value, 1, 1)
from Custom_Field
	inner join Address_Book_Custom_Field on Custom_Field.Custom_Field_id = Address_Book_Custom_Field.Custom_Field_id
where Custom_Field.Validation_Type = 1
	and Address_Book_Custom_Field.Custom_Value like '_/__/____'
GO


