truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.44');
GO

ALTER procedure [dbo].[spAddBk_AddressList]
	@AddressID int,
	@ErrorCode int = 0 output
AS
	SELECT *
	FROM Address_Book
	WHERE Address_ID = @AddressID;

	set @errorcode = @@error;

GO
