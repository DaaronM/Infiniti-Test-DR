/*
** Database Update package 6.3.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.3.1')
go

--1931
ALTER procedure [dbo].[spContent_ContentItemListByDefinition]
	@ContentDefinitionGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ErrorCode int output
as
	SELECT	ci.*, cdi.SortIndex, cib.FileType, cib.Modified_Date, Intelledox_User.Username
	FROM	content_item ci
			INNER JOIN content_definition_item cdi ON ci.ContentItem_Guid = cdi.ContentItem_Guid
				AND cdi.ContentDefinition_Guid = @ContentDefinitionGuid
			LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = cib.Modified_By
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
	ORDER BY cdi.SortIndex;
	
	set @ErrorCode = @@error;
GO


