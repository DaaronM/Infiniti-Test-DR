/*
** Database Update package 5.1.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.3')
go

--1845
ALTER PROCEDURE [dbo].[spGetBilling]
AS
	DECLARE @CurrentDate DateTime
	DECLARE @LicenseHolder NVarchar(1000)
	
	SET NOCOUNT ON
	
	SET @CurrentDate = CAST(CONVERT(Varchar(10), GETDATE(), 102) AS DateTime)
	
	SELECT	@LicenseHolder = OptionValue 
	FROM	Global_Options
	WHERE	OptionCode = 'LICENSE_HOLDER'

	SELECT	@LicenseHolder as LicenseHolder, CONVERT(Varchar(10), Template_Log.DateTime_Finish, 102) as ActivityDate, 
			IsNull(Template.Name, '') as ProjectName, COUNT(*) AS DocumentCount
	FROM	Template_Log
			LEFT JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
			LEFT JOIN Template_Group_Item ON Template_Group.Template_Group_ID = Template_Group_Item.Template_Group_ID
			LEFT JOIN Template ON Template_Group_Item.Template_Id = Template.Template_Id
	WHERE	Template_Log.Completed = 1
			AND Template_Log.DateTime_Finish BETWEEN DATEADD(d, -30, @CurrentDate) AND @CurrentDate
	GROUP BY CONVERT(Varchar(10), Template_Log.DateTime_Finish, 102), IsNull(Template.Name, '')
GO


