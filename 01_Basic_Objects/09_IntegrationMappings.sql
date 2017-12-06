CREATE TABLE [dbo].[IntegrationMappings](
	[ID] [INT] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[IntegrationID] [INT] NOT NULL,
	[ColumnName] [VARCHAR](128) NOT NULL,
	[LevelID] [TINYINT] NOT NULL,
	[KeyName] [VARCHAR](255) NOT NULL,
)
