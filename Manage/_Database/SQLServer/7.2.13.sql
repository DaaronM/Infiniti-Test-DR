/*
** Database Update package 7.2.13
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('7.2.13');
go

--2010
ALTER TABLE Template_Styles
	ADD Bold bit null,
		Italic bit null,
		Underline bit null
GO
UPDATE	Template_Styles
SET		Bold = 0,
		Italic = 0,
		Underline = 0
GO
ALTER TABLE Template_Styles
	ALTER COLUMN Bold bit not null
ALTER TABLE Template_Styles
	ALTER COLUMN Italic bit not null
ALTER TABLE Template_Styles
	ALTER COLUMN Underline bit not null
GO
ALTER PROCEDURE [dbo].[spProject_UpdateStyle] (
	@ProjectGuid uniqueidentifier,
	@Title nvarchar(100),
	@FontName nvarchar(100),
	@Size decimal,
	@FontColour int,
	@Bold bit,
	@Italic bit,
	@Underline bit)
AS
	INSERT INTO Template_Styles (ProjectGuid, Title, FontName, Size, FontColour, Bold, Italic, Underline)
	VALUES (@ProjectGuid, @Title, @FontName, @Size, @FontColour, @Bold, @Italic, @Underline);
GO

--2011
DROP TABLE dbo.Image_Library;
GO


