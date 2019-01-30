/*
** Database Update package 8.1.2
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.1.2');
go

--2065
ALTER TABLE dbo.Group_Output ADD
	EmbedFullFonts bit NOT NULL CONSTRAINT DF_Group_Output_EmbedFullFonts DEFAULT 0;
GO

ALTER PROCEDURE [dbo].[spTemplateGrp_UpdateGroupOutput]
	@GroupGuid uniqueidentifier,
	@FormatTypeId int,
	@LockOutput bit,
	@EmbedFullFonts bit
AS
	IF NOT EXISTS(SELECT * FROM Group_Output WHERE GroupGuid = @GroupGuid AND FormatTypeId = @FormatTypeId)
	BEGIN
		INSERT INTO Group_Output (GroupGuid, FormatTypeId, LockOutput, EmbedFullFonts)
		VALUES (@GroupGuid, @FormatTypeId, @LockOutput, @EmbedFullFonts)
	END	
	ELSE
	BEGIN		
		UPDATE	Group_Output
		SET		LockOutput = @LockOutput,
				EmbedFullFonts = @EmbedFullFonts
		WHERE	GroupGuid = @GroupGuid
			AND FormatTypeId = @FormatTypeId
	END
GO

--2066

INSERT INTO Global_Options (OptionCode, OptionDescription, OptionValue)
VALUES ('PDF_EMBED_FONTS', 'Default for PDF Full Font Embedding', 0);
GO

