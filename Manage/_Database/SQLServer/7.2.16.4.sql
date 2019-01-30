/*
** Database Update package 7.2.16.4
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('7.2.16.4');
go

--2020

  UPDATE dbo.Routing_Type
  SET ProviderType = 2
  WHERE RoutingTypeId = '230DD56C-0018-4D49-945E-5B6E5B08EAF6';
GO


