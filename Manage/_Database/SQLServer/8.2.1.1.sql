/*
** Database Update package 8.2.1.1
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.1.1');
go
ALTER procedure [dbo].[spDocument_Cleanup]
AS
	SET NOCOUNT ON

	WHILE (1=1)
	BEGIN
		DELETE TOP(200) FROM Document
		WHERE	Downloadable = 0 
			AND DateCreated < DATEADD(hour, -CAST((SELECT OptionValue 
										FROM Global_Options 
										WHERE OptionCode = 'CLEANUP_HOURS') AS float), GetUtcDate());

		IF (@@ROWCOUNT < 200) break;
	END
go
