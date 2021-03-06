truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.0.0.6');
go

ALTER TABLE dbo.CustomQuestion_Type ADD
	[ModuleId] nvarchar(4) NULL
GO

ALTER PROCEDURE [dbo].[spCustomQuestion_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@Icon varbinary(MAX),
	@ModuleId nvarchar(4) = NULL

AS
	IF NOT EXISTS(SELECT * FROM CustomQuestion_Type WHERE CustomQuestionTypeId = @id)
	BEGIN
		INSERT INTO CustomQuestion_Type(CustomQuestionTypeId, Description, Icon, ModuleId)
		VALUES	(@id, @Description, @Icon, @ModuleId);
	END

GO

--Delete Routing and associated element data for the Create User Action, 
--as require the parameters to re-register on subsequent produce load
DELETE FROM dbo.Routing_ElementType
WHERE RoutingTypeId = '085D87A5-14F1-4F78-BC79-54D06B924F8D'
GO

DELETE FROM dbo.Routing_Type
WHERE RoutingTypeId = '085D87A5-14F1-4F78-BC79-54D06B924F8D'
GO
