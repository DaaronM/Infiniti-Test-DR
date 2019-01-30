/*
** Database Update package 6.2.12
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.12')
go

--1926
INSERT INTO Routing_ElementType(RoutingElementTypeId, RoutingTypeId, ElementTypeDescription, ElementLimit, Required)
VALUES ('4C6D71D1-29A0-4AB8-8CBA-945B38491459', '230DD56C-0018-4D49-945E-5B6E5B08EAF6', 'Mht Body Document', 1, 0)
GO


