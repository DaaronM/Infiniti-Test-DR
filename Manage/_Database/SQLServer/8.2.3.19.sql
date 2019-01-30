/*
** Database Update package 8.2.3.19
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.3.19');
go
ALTER procedure [dbo].[spDocument_Cleanup]
AS
    SET NOCOUNT ON

    DECLARE @CleanupDate DateTime;
    DECLARE @DownloadableDocNum int;

    SET @CleanupDate = DATEADD(hour, -CAST((SELECT OptionValue 
                                        FROM Global_Options 
                                        WHERE OptionCode = 'CLEANUP_HOURS') AS float), GetUtcDate());

    SET @DownloadableDocNum = (SELECT OptionValue 
                                FROM Global_Options 
                                WHERE OptionCode = 'DOWNLOADABLE_DOC_NUM');

    SET DEADLOCK_PRIORITY LOW;

    WHILE (1=1)
    BEGIN
        IF (@DownloadableDocNum = 0)
        BEGIN
            DELETE TOP(200) FROM Document
            WHERE	DateCreated < @CleanupDate;
        END
        ELSE
        BEGIN
            -- Get the last N jobs grouped by user
            WITH GroupedDocuments AS (
                SELECT JobId, ROW_NUMBER()
                OVER (PARTITION BY UserGuid ORDER BY DateCreated DESC) AS RN
                FROM (
                    SELECT	JobId, UserGuid, DateCreated
                    FROM	Document WITH (NOLOCK)
                    GROUP BY JobId, UserGuid, DateCreated
                    ) ds
                )
            DELETE TOP(200) FROM Document
            WHERE DateCreated < @CleanupDate
                AND JobId NOT IN (
                    SELECT	JobId
                    FROM	GroupedDocuments WITH (NOLOCK)
                    WHERE	RN <= @DownloadableDocNum
                );
        END

        IF (@@ROWCOUNT < 200) break;
    END

    SET DEADLOCK_PRIORITY NORMAL;
GO
ALTER procedure [dbo].[spDocument_GetCleanupJobs]
AS
    DECLARE @CleanupDate DateTime;
    DECLARE @DownloadableDocNum int;

    SET @CleanupDate = DATEADD(hour, -CAST((SELECT OptionValue 
                                        FROM Global_Options 
                                        WHERE OptionCode = 'CLEANUP_HOURS') AS float), GetUtcDate());

    SET @DownloadableDocNum = (SELECT OptionValue 
                                FROM Global_Options 
                                WHERE OptionCode = 'DOWNLOADABLE_DOC_NUM');

    IF (@DownloadableDocNum = 0)
    BEGIN
        SELECT JobId
        FROM Document WITH (NOLOCK)
        WHERE DateCreated < @CleanupDate;
    END
    ELSE
    BEGIN
        -- Get the last N jobs grouped by user
        WITH GroupedDocuments AS (
            SELECT JobId, ROW_NUMBER()
            OVER (PARTITION BY UserGuid ORDER BY DateCreated DESC) AS RN
            FROM (
                SELECT	JobId, UserGuid, DateCreated
                FROM	Document WITH (NOLOCK)
                GROUP BY JobId, UserGuid, DateCreated
                ) ds
            )
        SELECT JobId
        FROM Document WITH (NOLOCK)
        WHERE DateCreated < @CleanupDate
            AND JobId NOT IN (
                
                SELECT	JobId
                FROM	GroupedDocuments WITH (NOLOCK)
                WHERE	RN <= @DownloadableDocNum
            );
    END
GO
ALTER PROCEDURE [dbo].[spDocument_InsertDocument]
    @DocumentId uniqueidentifier,
    @Extension nvarchar(10),
    @JobId uniqueidentifier,
    @UserGuid uniqueidentifier,
    @DisplayName nvarchar(255),
    @DateCreated datetime,
    @DocumentBinary varbinary(max),
    @DocumentLength int,
    @ProjectDocumentGuid uniqueidentifier,
    @ActionOnly bit
as
    INSERT INTO Document(DocumentId, 
        Extension, 
        JobId, 
        UserGuid, 
        DisplayName, 
        DateCreated, 
        DocumentBinary, 
        DocumentLength,
        ProjectDocumentGuid,
        Downloadable,
        ActionOnly)
    VALUES (@DocumentId, 
        @Extension, 
        @JobId, 
        @UserGuid, 
        @DisplayName, 
        @DateCreated, 
        @DocumentBinary, 
        @DocumentLength,
        @ProjectDocumentGuid,
        CASE WHEN @ActionOnly = 1 THEN 0 ELSE 1 END,
        @ActionOnly);
GO
