truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.7.1.4');
go
IF NOT EXISTS(SELECT * FROM Global_Options WHERE OptionCode = 'USERNAME_TEXT')
BEGIN
INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'USERNAME_TEXT', 'Text to be displayed for the Username field', '');
END
GO





