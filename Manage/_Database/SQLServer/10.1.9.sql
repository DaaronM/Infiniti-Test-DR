truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.1.9');
GO
ALTER VIEW vwUserDocuments
AS
	SELECT Document.DocumentId,   
		Document.Extension,    
		Document.DisplayName,    
		Document.ProjectDocumentGuid,    
		Document.DateCreated,    
		Document.JobId,  
		Document.ActionOnly,  
		Document.RepeatIndices,  
		Template.Name As ProjectName,
		Document.UserGuid,
		Template.Business_Unit_Guid
	FROM Document WITH (NOLOCK)  
		INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId  
		INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid  
		INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid  
	WHERE Document.Downloadable = 1  AND Document.DocumentLength <> -1
GO
