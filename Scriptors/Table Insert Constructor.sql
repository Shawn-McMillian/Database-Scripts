SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Table Insert Constructor
**
** Created By:  Shawn McMillian
**
** Description: Based on the table name provided, Construct an insert statement for the table based on a select from table
**
** Databases:   Common
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** Aug 09 2017					Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/

--Set the loacal variables for the script
DECLARE @TableName nvarchar(256),
		@DataStatement nvarchar(max),
		@InsertScript nvarchar(max),
		@ValuesScript nvarchar(max) = '',
		@ValuesScriptLoop nvarchar(max),
		@ColumnID int,
		@RowCount int,
		@MaxRowCount int,
		@MaxColumnID int,
		@ColumnName sysname,
		@DataType nvarchar(128),
		@SQL nvarchar(max),
		@Params nvarchar(max),
		@ColumnValueText nvarchar(max),
		@ColumnValueDateTime nvarchar(30)

--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @TableName = '[dbo].[UserGroup]'
SET @DataStatement = 'SELECT ROW_NUMBER() OVER (ORDER BY UserGroupId) AS ROW_NUMBER,* INTO ##InsertScriptor FROM [DBAdmin].[dbo].[UserGroup]'

--*************************************************************************************
--****					     Construct the temp table   						   ****
--*************************************************************************************
IF (SELECT OBJECT_ID('tempdb..##InsertScriptor')) IS NOT NULL
	BEGIN
	DROP TABLE ##InsertScriptor
	END

EXEC [master].[dbo].[sp_executesql] @Query = @DataStatement;

--*************************************************************************************
--****					 Construct the Insert portion 							   ****
--*************************************************************************************
SET @InsertScript = 'INSERT INTO ' + @TableName + '('

--Insert the column names
SELECT @InsertScript = @InsertScript  + '[' + [name] + '],' 
FROM [tempdb].[sys].[columns]
WHERE object_id = OBJECT_ID('tempdb..##InsertScriptor')
AND Column_id > 1
ORDER BY column_id

--clean up the Insert script
SET @InsertScript = STUFF(@InsertScript,LEN(@InsertScript),1,')')

--*************************************************************************************
--****					 Construct the values portion 							   ****
--*************************************************************************************
--Set the values for the loops
SET @ColumnID = 2
SET @RowCount = 1
SELECT @MaxRowCount = MAX(ROW_NUMBER) FROM ##InsertScriptor
SELECT @MaxColumnID = MAX(column_id) FROM [tempdb].[sys].[columns] AS C WHERE object_id = OBJECT_ID('tempdb..##InsertScriptor')

--Loop through the rows
WHILE @RowCount <= @MaxRowCount
	BEGIN
	IF @RowCount = 1
		BEGIN
		SET @ValuesScriptLoop = 'VALUES('
		END
	ELSE
		BEGIN
		SET @ValuesScriptLoop = ',('
		END
	
	--Loop through each column and process
	WHILE @ColumnID <= @MaxColumnID
		BEGIN
		--Get the column to process
		SELECT	@ColumnName = C.[Name],
				@DataType = T.[name]
		FROM tempdb.sys.columns AS C
			JOIN sys.types AS T ON C.user_type_id = T.user_type_id
		WHERE object_id = OBJECT_ID('tempdb..##InsertScriptor')
		AND C.Column_id = @ColumnID
		ORDER BY column_id

		--Use the data type to chose the correct dynamic sql to execute
		IF @DataType IN('image','text','uniqueidentifier','date','time','datetime2','datetimeoffset','smalldatetime','sql_variant','varbinary','varchar','binary','char','timestamp','xml','sysname','ntext','nvarchar','nchar')
			BEGIN
			--Set the dynmaic SQL and parameters for this type
			SET @SQL = 'SELECT @ColumnValueText = [' + @ColumnName + '] FROM ##InsertScriptor WHERE ROW_NUMBER = ' + CAST(@RowCount AS varchar(10))
			SET @Params = '@ColumnValueText nvarchar(max) OUTPUT'

			--Execure the dynamic SQL to bring the table value into a parameter that we can use
			EXEC master.dbo.sp_executesql @Query = @SQL, @Params = @Params, @ColumnValueText = @ColumnValueText OUTPUT

			--Handle NULLS
			IF @ColumnValueText IS NULL
				BEGIN
				SET @ValuesScriptLoop = @ValuesScriptLoop + 'NULL,'
				END
			ELSE
				BEGIN
				SET @ValuesScriptLoop = @ValuesScriptLoop + '''' + @ColumnValueText + ''','
				END
			END

		IF @DataType IN('tinyint','smallint','int','real','money','float','bit','decimal','numeric','smallmoney','bigint')
			BEGIN
			--Set the dynmaic SQL and parameters for this type
			SET @SQL = 'SELECT @ColumnValueText = [' + @ColumnName + '] FROM ##InsertScriptor WHERE ROW_NUMBER = ' + CAST(@RowCount AS varchar(10))
			SET @Params = '@ColumnValueText nvarchar(max) OUTPUT'

			--Execure the dynamic SQL to bring the table value into a parameter that we can use
			EXEC master.dbo.sp_executesql @Query = @SQL, @Params = @Params, @ColumnValueText = @ColumnValueText OUTPUT

			--Handle NULLS
			IF @ColumnValueText IS NULL
				BEGIN
				SET @ValuesScriptLoop = @ValuesScriptLoop + 'NULL,'
				END
			ELSE
				BEGIN
				SET @ValuesScriptLoop = @ValuesScriptLoop + @ColumnValueText + ','
				END

			END

		IF @DataType IN('datetime')
			BEGIN
			--Set the dynmaic SQL and parameters for this type
			SET @SQL = 'SELECT @ColumnValueDateTime = CONVERT(nvarchar(30),[' + @ColumnName + '],121) FROM ##InsertScriptor WHERE ROW_NUMBER = ' + CAST(@RowCount AS varchar(10))
			SET @Params = '@ColumnValueDateTime nvarchar(30) OUTPUT'

			--Execure the dynamic SQL to bring the table value into a parameter that we can use
			EXEC master.dbo.sp_executesql @Query = @SQL, @Params = @Params, @ColumnValueDateTime = @ColumnValueDateTime OUTPUT

			--Handle NULLS
			IF @ColumnValueDateTime IS NULL
				BEGIN
				SET @ValuesScriptLoop = @ValuesScriptLoop + 'NULL,'
				END
			ELSE
				BEGIN
				SET @ValuesScriptLoop = @ValuesScriptLoop + '''' + @ColumnValueDateTime + ''','
				END
			END 

		--Increment the column loop
		SET @ColumnID = @ColumnID + 1
		END--Column loop

	--clean up the Value script
	SET @ValuesScriptLoop = STUFF(@ValuesScriptLoop,LEN(@ValuesScriptLoop),1,')')
	SET @ValuesScript = @ValuesScript + @ValuesScriptLoop + CHAR(13)

	--Increment the row loop
	SET @RowCount = @RowCount + 1
	SET @ColumnID = 2
	END --Row Loop

	
--*************************************************************************************
--****					         Put it all together 							   ****
--*************************************************************************************
--clean up the Insert script
SET @InsertScript = STUFF(@InsertScript,LEN(@InsertScript),1,')')

--Print the results
PRINT @InsertScript
PRINT @ValuesScript

