/*
** Database Update package 6.2.4.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.4.2')
go

--1914
ALTER PROCEDURE [dbo].[spRouting_RegisterTypeAttribute]
	@RoutingTypeId uniqueidentifier,
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit
AS
	IF NOT EXISTS(SELECT * FROM Routing_ElementType WHERE RoutingElementTypeId = @Id AND RoutingTypeId = @RoutingTypeId)
	BEGIN
		INSERT INTO Routing_ElementType(RoutingElementTypeId, RoutingTypeId, ElementTypeDescription, ElementLimit, [Required])
		VALUES	(@Id, @RoutingTypeId, @Description, @ElementLimit, @Required);
	END
GO


