truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.0.60');
GO

-- DROP/CREATE PROC that was contained in this file in 10.0.60 has been moved to 10.2.1.sql
