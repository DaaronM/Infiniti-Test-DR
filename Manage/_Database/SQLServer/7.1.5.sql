/*
** Database Update package 7.1.5
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.5')
go

--1970
ALTER TABLE data_service
	ALTER COLUMN connection_string NVARCHAR(MAX) null;
GO
ALTER PROCEDURE [dbo].[spDataSource_UpdateDataService]
	@DataServiceGuid uniqueidentifier,
	@Name nvarchar(100),
	@ConnectionString nvarchar(MAX),
	@AllowUpdate bit,
	@CredentialMethod int,
	@AllowConnectionExport bit,
	@BusinessUnitGuid uniqueidentifier,
	@ProviderName nvarchar(100),
	@AllowInsert bit,
	@Username nvarchar(100),
	@PasswordHash varchar(1000)
as
	IF NOT EXISTS(SELECT * FROM Data_Service WHERE data_service_guid = @DataServiceGuid)
		INSERT INTO Data_Service ([name], connection_string, allow_writeback, data_service_guid, 
				Credential_Method, Allow_Connection_Export, Business_Unit_Guid, Provider_Name, 
				Allow_Insert, Username, PasswordHash)
		VALUES (@Name, @ConnectionString, @AllowUpdate, @DataServiceGuid, 
				@CredentialMethod, @AllowConnectionExport, @BusinessUnitGuid, @ProviderName, 
				@AllowInsert, @Username, @PasswordHash);
	ELSE
		UPDATE Data_Service
		SET [name] = @Name,
			connection_string = @ConnectionString,
			allow_writeback = @AllowUpdate,
			Credential_Method = @CredentialMethod,
			Allow_Connection_Export = @AllowConnectionExport,
			Business_Unit_Guid = @BusinessUnitGuid,
			Provider_Name = @ProviderName,
			Allow_Insert = @AllowInsert,
			Username = @Username,
			PasswordHash = @PasswordHash
		WHERE Data_Service_Guid = @DataServiceGuid;
GO

