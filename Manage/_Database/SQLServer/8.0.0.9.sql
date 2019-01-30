/*
** Database Update package 8.0.0.9
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0.9');
go

--2042
/**DROP AND RECREATE Routing_ElementType TABLE**/
GO
DROP TABLE [dbo].[Routing_Type]
GO

CREATE TABLE [dbo].[Routing_Type](
	[RoutingTypeId] [uniqueidentifier] NOT NULL,
	[RoutingTypeDescription] [nvarchar](255) NULL,
	[ProviderType] [int] NULL,
	[RunForAllProjects] [bit] NOT NULL,
	[SupportsUI] [bit] NULL,
	[SupportsRun] [bit] NULL,
 CONSTRAINT [PK_Routing_Type_Guid] PRIMARY KEY CLUSTERED 
(
	[RoutingTypeId] ASC
)
)

GO

ALTER TABLE [dbo].[Routing_Type] ADD  DEFAULT ((0)) FOR [RunForAllProjects]
GO

/**Clean up routing elements **/
DELETE FROM Routing_ElementType

/**Update Stored Procedure**/

GO
ALTER PROCEDURE [dbo].[spRouting_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ProviderType int,
	@RunForAllProjects bit,
	@SupportsRun bit,
	@SupportsUI bit

AS
	IF NOT EXISTS(SELECT * FROM Routing_Type WHERE RoutingTypeId = @id)
	BEGIN
		INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription, ProviderType, RunForAllProjects, SupportsRun, SupportsUI)
		VALUES	(@id, @Description, @ProviderType, @RunForAllProjects, @SupportsRun, @SupportsUI);
	END
GO


