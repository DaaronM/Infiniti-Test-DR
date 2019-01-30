truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.3.4');
go

ALTER TABLE Template_Group
DROP COLUMN MatchProjectVersion;
GO
ALTER TABLE Template_Group
ADD MatchProjectVersion bit NOT NULL DEFAULT 0;
GO

ALTER TABLE Answer_File
DROP COLUMN FirstLaunchTimeUtc;
GO
ALTER TABLE Answer_File
ADD FirstLaunchTimeUtc datetime NOT NULL DEFAULT GETUTCDATE();
GO
