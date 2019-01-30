/*
** Database Update package 7.2.12
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('7.2.12');
go

--2008
INSERT INTO Global_Options (OptionCode, OptionDescription, OptionValue)
VALUES ('DOCX_FORMAT', 'Default Docx format', '0');
GO
IF EXISTS(SELECT * FROM Global_Options WHERE OptionCode = 'PDF_FORMAT' AND OptionValue = '1')
BEGIN
	UPDATE	Group_Output
	SET		FormatTypeId = 10
	WHERE	FormatTypeId = 4;
END
GO

--2009
CREATE TABLE dbo.Template_Styles
	(
	ProjectGuid uniqueidentifier NOT NULL,
	Title nvarchar(100) NOT NULL,
	FontName nvarchar(100) NOT NULL,
	Size decimal(9, 3) NOT NULL,
	FontColour int NOT NULL
	)
GO
CREATE CLUSTERED INDEX IX_Template_Styles_ProjectGuid ON dbo.Template_Styles
	(
	ProjectGuid
	)
GO
CREATE PROCEDURE spProject_RemoveStyles (
	@ProjectGuid uniqueidentifier)
AS
	DELETE FROM	Template_Styles
	WHERE ProjectGuid = @ProjectGuid;
GO
CREATE PROCEDURE spProject_UpdateStyle (
	@ProjectGuid uniqueidentifier,
	@Title nvarchar(100),
	@FontName nvarchar(100),
	@Size decimal,
	@FontColour int)
AS
	INSERT INTO Template_Styles (ProjectGuid, Title, FontName, Size, FontColour)
	VALUES (@ProjectGuid, @Title, @FontName, @Size, @FontColour);
GO
CREATE PROCEDURE spProject_StylesList (
	@ProjectGuid uniqueidentifier)
AS
	SELECT	*
	FROM	Template_Styles
	WHERE	ProjectGuid = @ProjectGuid;
GO

