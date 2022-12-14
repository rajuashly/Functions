USE [RMSHybrid]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_FetchWeekdayCount]    Script Date: 2022/08/26 08:43:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_FetchWeekdayCount]
(
	@startDate DATETIME,
	@endDate DATETIME
)
RETURNS INT
AS
BEGIN

	DECLARE @totaldays INT; 
	DECLARE @weekenddays INT;

	SET @totaldays = DATEDIFF(DAY, @startDate, @endDate) 
	SET @weekenddays = ((DATEDIFF(WEEK, @startDate, @endDate) * 2) + -- get the number of weekend days in between
						   CASE WHEN DATEPART(WEEKDAY, @startDate) = 1 THEN 1 ELSE 0 END + -- if selection was Sunday, won't add to weekends
						   CASE WHEN DATEPART(WEEKDAY, @endDate) = 6 THEN 1 ELSE 0 END)  -- if selection was Saturday, won't add to weekends

	RETURN (@totaldays - @weekenddays)

END
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetUserCodebyEmail]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnGetUserCodebyEmail]
(
@EmailAddress as varchar(1000)
)
RETURNS varchar(1000)
AS
BEGIN

declare @UserCode as varchar(8000) = ''

  if exists(select top 1 DACemail from PR_DACUserHierarchy where DACemail = @EmailAddress)
  begin
  	DECLARE @list varchar(8000)
  	DECLARE @pos INT
  	DECLARE @len INT
  	DECLARE @value varchar(8000)
  
  	SET @list = (select top 1 DACUserAssigned from PR_DACUserHierarchy where DACemail = @EmailAddress)
  
  
  	set @pos = 0
  	set @len = 0
  
  	if (CHARINDEX(',', @list, @pos+1)>0)
  	begin
  		set @list = @list + ','
  		WHILE CHARINDEX(',', @list, @pos+1)>0
  		BEGIN
  			set @len = CHARINDEX(',', @list, @pos+1) - @pos
  			set @value = SUBSTRING(@list, @pos, @len)
  			set @UserCode += ',' + (select top 1 isnull(UserCode,'') from [User] where Email = @value)
  			set @pos = CHARINDEX(',', @list, @pos+@len) +1
  		END	
  	end
  	else
  	begin
  		if (@list is not null and @list <> '')
  			begin
  				set @UserCode += ','  + (select top 1 isnull(UserCode,'') from [User] where Email = @list) 
  			end
  	end
  end

  		if (CHARINDEX(',',@UserCode) = 1)
		  begin
			set @UserCode = SUBSTRING(@UserCode,2,len(@UserCode))
		  end

return @UserCode

END
GO
/****** Object:  UserDefinedFunction [dbo].[HTMLDecode]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[HTMLDecode] (@vcWhat VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @vcResult VARCHAR(MAX)
    DECLARE @siPos INT
        ,@vcEncoded VARCHAR(7)
        ,@siChar INT

    SET @vcResult = RTRIM(LTRIM(CAST(REPLACE(@vcWhat COLLATE Latin1_General_BIN, CHAR(0), '') AS VARCHAR(MAX))))

    SELECT @vcResult = REPLACE(REPLACE(@vcResult, '&#160;', ' '), '&nbsp;', ' ')

    IF @vcResult = ''
        RETURN @vcResult

    SELECT @siPos = PATINDEX('%&#[0-9][0-9][0-9];%', @vcResult)

    WHILE @siPos > 0
    BEGIN
        SELECT @vcEncoded = SUBSTRING(@vcResult, @siPos, 6)
            ,@siChar = CAST(SUBSTRING(@vcEncoded, 3, 3) AS INT)
            ,@vcResult = REPLACE(@vcResult, @vcEncoded, NCHAR(@siChar))
            ,@siPos = PATINDEX('%&#[0-9][0-9][0-9];%', @vcResult)
    END

    SELECT @siPos = PATINDEX('%&#[0-9][0-9][0-9][0-9];%', @vcResult)

    WHILE @siPos > 0
    BEGIN
        SELECT @vcEncoded = SUBSTRING(@vcResult, @siPos, 7)
            ,@siChar = CAST(SUBSTRING(@vcEncoded, 3, 4) AS INT)
            ,@vcResult = REPLACE(@vcResult, @vcEncoded, NCHAR(@siChar))
            ,@siPos = PATINDEX('%&#[0-9][0-9][0-9][0-9];%', @vcResult)
    END

    SELECT @siPos = PATINDEX('%#[0-9][0-9][0-9][0-9]%', @vcResult)

    WHILE @siPos > 0
    BEGIN
        SELECT @vcEncoded = SUBSTRING(@vcResult, @siPos, 5)
            ,@vcResult = REPLACE(@vcResult, @vcEncoded, '')
            ,@siPos = PATINDEX('%#[0-9][0-9][0-9][0-9]%', @vcResult)
    END

    SELECT @vcResult = REPLACE(REPLACE(@vcResult, NCHAR(160), ' '), CHAR(160), ' ')

    SELECT @vcResult = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@vcResult, '&amp;', '&'), '&quot;', '"'), '&lt;', '<'), '&gt;', '>'), '&amp;amp;', '&')

    RETURN @vcResult
END
GO
/****** Object:  UserDefinedFunction [dbo].[LookupCarraigeOrLineFeed]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[LookupCarraigeOrLineFeed]
(
      @String VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
BEGIN
DECLARE @RETURN_BOOLEAN INT

;WITH N1 (n) AS (SELECT 1 UNION ALL SELECT 1),
N2 (n) AS (SELECT 1 FROM N1 AS X, N1 AS Y),
N3 (n) AS (SELECT 1 FROM N2 AS X, N2 AS Y),
N4 (n) AS (SELECT ROW_NUMBER() OVER(ORDER BY X.n)
FROM N3 AS X, N3 AS Y)

SELECT @RETURN_BOOLEAN =COUNT(*)
FROM N4 Nums
WHERE Nums.n<=LEN(@String) AND ASCII(SUBSTRING(@String,Nums.n,1)) 
IN (13,10)    

RETURN (CASE WHEN @RETURN_BOOLEAN >0 THEN 'TRUE' ELSE 'FALSE' END)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Split]
(
	@RowData nvarchar(max),
	@SplitOn nvarchar(5)
)  
RETURNS @RtnValue table 
(
	Id int identity(1,1),
	Data nvarchar(100)
) 
AS  
BEGIN 
	Declare @Cnt int
	Set @Cnt = 1

	While (Charindex(@SplitOn,@RowData)>0)
	Begin
		Insert Into @RtnValue (data)
		Select 
			Data = ltrim(rtrim(Substring(@RowData,1,Charindex(@SplitOn,@RowData)-1)))

		Set @RowData = Substring(@RowData,Charindex(@SplitOn,@RowData)+1,len(@RowData))
		Set @Cnt = @Cnt + 1
	End

	Insert Into @RtnValue (data)
	Select Data = ltrim(rtrim(@RowData))

	Return
END

GO
/****** Object:  UserDefinedFunction [dbo].[StripHTML]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[StripHTML]( @text varchar(max) ) returns varchar(max) as
begin
    declare @textXML xml
    declare @result varchar(max)
    set @textXML = REPLACE( @text, '&',' ' );
	 --set @textXML = REPLACE( @text, char(13),' ' );
    with doc(contents) as
    (
        select chunks.chunk.query('.') from @textXML.nodes('/') as chunks(chunk)
    )
    select @result = contents.value('.', 'varchar(max)') from doc
    return @result
end
GO
/****** Object:  UserDefinedFunction [dbo].[StripHTMLAf]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[StripHTMLAf]

(
@HTML_STRING VARCHAR(MAX) 
)

RETURNS VARCHAR(MAX)

BEGIN

    DECLARE @STRING VARCHAR(MAX)
    Declare @Xml AS XML

    SET @Xml = CAST(('<A>'+ REPLACE(REPLACE(REPLACE(REPLACE(@HTML_STRING,'<','@*'),'>','!'),'@','</A><A>'),'!','</A><A>') +'</A>') AS XML)

       ;WITH CTE AS 
       
              (SELECT A.value('.', 'VARCHAR(MAX)') [A] 

         FROM @Xml.nodes('A') AS FN(A) 
               
               WHERE CHARINDEX('*', A.value('.', 'VARCHAR(MAX)'))=0 

         AND ISNULL(A.value('.', 'varchar(max)'),'')<>'')

    SELECT @STRING=STUFF((SELECT ' ' + [A] FROM CTE FOR XML PATH('')),1,1,'')

    RETURN @STRING

END
GO
/****** Object:  UserDefinedFunction [dbo].[udf_StripHTML]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_StripHTML] (@HTMLText VARCHAR(MAX))
RETURNS VARCHAR(MAX) AS
BEGIN
    DECLARE @Start INT
    DECLARE @End INT
    DECLARE @Length INT
    SET @Start = CHARINDEX('<',@HTMLText)
    SET @End = CHARINDEX('>',@HTMLText,CHARINDEX('<',@HTMLText))
    SET @Length = (@End - @Start) + 1
    WHILE @Start > 0 AND @End > 0 AND @Length > 0
    BEGIN
        SET @HTMLText = STUFF(@HTMLText,@Start,@Length,'')
        SET @Start = CHARINDEX('<',@HTMLText)
        SET @End = CHARINDEX('>',@HTMLText,CHARINDEX('<',@HTMLText))
        SET @Length = (@End - @Start) + 1
    END
    RETURN LTRIM(RTRIM(@HTMLText))
END
GO
/****** Object:  UserDefinedFunction [dbo].[udf_StripHTMLText]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[udf_StripHTMLText]
--by Patrick Honorez --- www.idevlop.com
--inspired by http://stackoverflow.com/questions/457701/best-way-to-strip-html-tags-from-a-string-in-sql-server/39253602#39253602
(
@HTMLText varchar(MAX)
)
RETURNS varchar(MAX)
AS
BEGIN
DECLARE @Start  int
DECLARE @End    int
DECLARE @Length int

set @HTMLText = replace(@htmlText, '<br>',CHAR(13) + CHAR(10))
set @HTMLText = replace(@htmlText, '<br/>',CHAR(13) + CHAR(10))
set @HTMLText = replace(@htmlText, '<br />',CHAR(13) + CHAR(10))
set @HTMLText = replace(@htmlText, '<li>','- ')
set @HTMLText = replace(@htmlText, '</li>',CHAR(13) + CHAR(10))

set @HTMLText = replace(@htmlText, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&quot;' collate Latin1_General_CS_AS, '"'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&quot;' collate Latin1_General_CS_AS, '"'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
set @HTMLText = replace(@htmlText, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)


-- Remove anything between <STYLE> tags
SET @Start = CHARINDEX('<STYLE', @HTMLText)
SET @End = CHARINDEX('</STYLE>', @HTMLText, CHARINDEX('<', @HTMLText)) + 7
SET @Length = (@End - @Start) + 1

WHILE (@Start > 0 AND @End > 0 AND @Length > 0) BEGIN
SET @HTMLText = STUFF(@HTMLText, @Start, @Length, '')
SET @Start = CHARINDEX('<STYLE', @HTMLText)
SET @End = CHARINDEX('</STYLE>', @HTMLText, CHARINDEX('</STYLE>', @HTMLText)) + 7
SET @Length = (@End - @Start) + 1
END

-- Remove anything between <whatever> tags
SET @Start = CHARINDEX('<', @HTMLText)
SET @End = CHARINDEX('>', @HTMLText, CHARINDEX('<', @HTMLText))
SET @Length = (@End - @Start) + 1

WHILE (@Start > 0 AND @End > 0 AND @Length > 0) BEGIN
SET @HTMLText = STUFF(@HTMLText, @Start, @Length, '')
SET @Start = CHARINDEX('<', @HTMLText)
SET @End = CHARINDEX('>', @HTMLText, CHARINDEX('<', @HTMLText))
SET @Length = (@End - @Start) + 1
END

RETURN LTRIM(RTRIM(@HTMLText))

END
GO
/****** Object:  UserDefinedFunction [dbo].[ufCalculateTimeSpent]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create   FUNCTION [dbo].[ufCalculateTimeSpent] 
	(@start DATETIME,@end DATETIME)
RETURNS varchar(500)
AS
BEGIN

	declare @x INT;

	SET @x = DATEDIFF(s, @start, @end);

	RETURN  CONVERT(VARCHAR(10), ( @x / 86400 )) + ' Days '
			+ CONVERT(VARCHAR(10), ( ( @x % 86400 ) / 3600 )) + ' Hours '
			+ CONVERT(VARCHAR(10), ( ( ( @x % 86400 ) % 3600 ) / 60 ))
			+ ' Minutes ' + CONVERT(VARCHAR(10), ( ( ( @x % 86400 ) % 3600 ) % 60 ))
			+ ' Seconds';
END




GO
/****** Object:  UserDefinedFunction [dbo].[ufCalculateWorkDaysForDates]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[ufCalculateWorkDaysForDates] 
	(@startDate DATETIME,@endDate DATETIME)
RETURNS INT
AS
BEGIN
	declare @counts int
	set @counts = 0

	while (@startdate <= @enddate)
	begin
		if ((SUBSTRING(DATENAME(dw,@startdate),1,1) <> 'S') and (Not Exists(select * from PublicHolidays where PublicHoliday = @startdate)))
			begin
				set @counts = @counts + 1
			end
		set @startdate = (select DATEADD(day,1,@startdate))
	end

	RETURN @counts
END




GO
/****** Object:  UserDefinedFunction [dbo].[ufCheckDateWeekend]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[ufCheckDateWeekend] 
	(@startDate DATETIME)
RETURNS DATETIME
AS
BEGIN
		--Rule 1: Date Cannot be in the weekend.
		IF(DATENAME(dw,@startDate) = 'Sunday') 
		BEGIN
			--Falls on a Sunday
			SET @startDate = DATEADD(day,CONVERT(BIGINT,(-2)), @startDate)
		END
		ELSE
		IF(DATENAME(dw,@startDate) = 'Saturday')
		BEGIN

			--Falls on a Saturday
			SET @startDate = DATEADD(day,CONVERT(BIGINT,(-1)), @startDate)

		END

	RETURN @startDate
END




GO
/****** Object:  UserDefinedFunction [dbo].[ufCheckPublicHolidays]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[ufCheckPublicHolidays]
      (@startDate DATETIME)
RETURNS DATETIME
AS
BEGIN

      --Check if it falls on a public holiday
      DECLARE @sDate DATETIME
      
      --Declare a cursor variable
      DECLARE my_cursor CURSOR STATIC FOR
      
      SELECT PublicHoliday FROM PublicHolidays 

      --Open the cursor
      OPEN my_cursor
      
      --Fetch the first record and put into the cursor
      FETCH NEXT FROM my_cursor INTO @sDate

      --Check the fetch status
      WHILE @@FETCH_STATUS = 0
      
      BEGIN
            --date passed == to a public holiday
            IF @startDate = @sDate
            BEGIN
                  SET @startDate = DATEADD(day,CONVERT(BIGINT,(-1)), @startDate)

                  --Rule 1: Date Cannot be in the weekend.
                  SET @startDate = dbo.ufCheckDateWeekend(@startDate)

                  SET @startDate = dbo.ufCheckPublicHolidays(@startDate)
            END
            
      --Fetch the first record and put into the cursor
      FETCH NEXT FROM my_cursor INTO @sDate

      END

      --Close the cursor
      CLOSE my_cursor
      
      --deallocate the cursor
      DEALLOCATE my_cursor

      RETURN @startDate
END
GO
/****** Object:  UserDefinedFunction [dbo].[ufGetNextWorkflowStageDate]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ufGetNextWorkflowStageDate] 
	(@startDate DATETIME, @JobID bigint, @CampaignID bigint, @CPASortID bigint)
RETURNS Datetime
AS
BEGIN
	declare @NextCPADate varchar(max)
	select @NextCPADate = coalesce(@NextCPADate + ',', '') + cast(CONVERT(VARCHAR(20),cp.StartDate,111) as varchar(20)) 
					  from CPAStageAdmin csa
					  join CPAStage cs on (cs.CPAAdminID = csa.CPAAdminID)
					  join cpa cp on (cp.StageID = cs.CPAStageID)
					  where cp.StartDate >= @startDate and cp.JobID = @JobID and cp.CampaignID = @CampaignID and csa.SortID > @CPASortID
					  order by csa.SortID asc
				if (CHARINDEX(',',@NextCPADate) = 0 and CHARINDEX('/',@NextCPADate) > 0)
					begin
						set @NextCPADate =  @NextCPADate
					end
				else
					begin
						set @NextCPADate =  (select SUBSTRING (@NextCPADate,0,charindex(',',@NextCPADate)))
					end
	if (@NextCPADate is null)
		begin
			set @NextCPADate = @startDate
		end

	RETURN @NextCPADate
END




GO
/****** Object:  UserDefinedFunction [dbo].[upGetPremediaBudgetValueByJob]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[upGetPremediaBudgetValueByJob] -- '1 oct 2018','30 oct 2018' 
( @jobID as bigint ) returns numeric(18,0) 

AS
BEGIN


	/*
	declare @jobid as bigint
	set @jobid = 96547
	*/

	declare @PreMediaCost as Numeric(18,0)

declare @wkPre2 TABLE (ID int , RegionName varchar(255),RegionCode varchar(255),InsertDate datetime,JobNumber varchar(255), Division  varchar(255),Medium varchar(255), Publication  varchar(255),  
Size varchar(255),Language varchar(255), SQCM  numeric(18,0),PreMediaCost numeric(18,0),MaterialDev numeric(18,0))

declare @wkPre TABLE (ID int , JobNumber varchar(255), Language varchar(255), Medium varchar(255), Size varchar(255), SQCM  numeric(18,0),PreMediaCost numeric(18,0))


insert into @wkPre2 
(ID  , RegionName ,RegionCode ,InsertDate ,JobNumber , Division  ,Medium , Publication, Size ,Language , SQCM ,PreMediaCost ,MaterialDev  )
SELECT jp.JobPublicationID,r.RegionName,R.RegionCode, j.InsertDate,j.JobNumber as KeyNumber, d.Division as [JobDescription], m.Medium, p.Name + '('+ jmg.Centrespread +')' as Publication,
jmg.SinglePage as Size,l.Language, case when isnumeric(jmg.trim) = 1 then jmg.trim else '0' end as SQCM, SUM(CAST(0 AS DECIMAL(10,0))*0.63) AS PreMediaCost,
SUM(CAST( rtrim(ltrim(case when isnumeric(jmg.trim) = 1 then jmg.trim else '0' end)) AS DECIMAL(10,0))* 0.18) AS MaterialDev
--into #wkPre2 
FROM dbo.Job j
JOIN dbo.Element e on e.ElementID=j.DescriptionID
JOIN dbo.Division d on d.DivisionID=j.DivisionID
JOIN dbo.Medium m on m.MeduimID=j.MediumID
join Region r on j.RegionID = r.RegionID
join dbo.JobMediaGrid jmg on jmg.JobID=j.jobid
join dbo.JobPublication jp on jp.jobid=j.jobid
join dbo.Publication p on p.PublicationID=jp.PublicationID and p.MediaGridID=jmg.MediaGridID
JOIN dbo.[Language] l on l.LanguageID= p.LanguageID
where jp.jobid = @jobID 
and jp.Deleted = 0
GROUP BY
       jp.JobPublicationID,r.RegionName,R.RegionCode,j.InsertDate,j.JobNumber, d.Division, m.Medium, p.Name,jmg.Centrespread, 
       jmg.SinglePage,l.Language, jmg.Trim, jp.publicationdate


insert into @wkPre (ID , JobNumber, Language , Medium , Size , SQCM ,PreMediaCost )
SELECT distinct 0 as JobPublicationID,
j.JobNumber as KeyNumber, l.Language, m.Medium, jmg.SinglePage as Size,case when isnumeric(jmg.trim) = 1 then jmg.trim else '0' end as SQCM, 
SUM(CAST(rtrim(ltrim(case when isnumeric(jmg.trim) = 1 then jmg.trim else '0' end))  AS DECIMAL(10,0))* 0.63) AS PreMediaCost      
--into #wkPre 
FROM dbo.Job j
JOIN dbo.Element e on e.ElementID=j.DescriptionID
JOIN dbo.Division d on d.DivisionID=j.DivisionID
JOIN dbo.Medium m on m.MeduimID=j.MediumID
join dbo.JobMediaGrid jmg on jmg.JobID=j.jobid
join dbo.JobPublication jp on jp.jobid=j.jobid
join dbo.Publication p on p.PublicationID=jp.PublicationID and p.MediaGridID=jmg.MediaGridID
JOIN dbo.[Language] l on l.LanguageID= p.LanguageID
where jp.jobid = @jobID 
and jp.Deleted = 0
GROUP BY
       jp.JobPublicationID,j.InsertDate,j.JobNumber, d.Division, m.Medium, p.Name,jmg.Centrespread, 
       jmg.SinglePage,l.Language, jmg.Trim, jp.publicationdate


UPDATE 
    wk1
SET
    wk1.ID = wk2.ID
FROM
     @wkPre2 wk2
left JOIN
     @wkPre wk1
ON 
   wk2.JobNumber = wk1.JobNumber and wk2.Medium = wk1.Medium 
   and wk2.SQCM = wk1.SQCM and wk2.Size = wk1.Size and wk2.Language = wk1.Language

UPDATE 
    wk1
SET
    wk1.PreMediaCost = wk2.PreMediaCost
FROM
     @wkPre wk2
left JOIN
     @wkPre2 wk1
ON 
   wk2.ID = wk1.Id 
   and wk2.JobNumber = wk1.JobNumber

select @PreMediaCost =  sum(PreMediaCost) from @wkPre2 
 RETURN  @PreMediaCost

END
GO
/****** Object:  UserDefinedFunction [dbo].[usp_ClearHTMLTags]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[usp_ClearHTMLTags] 
    (@String NVARCHAR(MAX)) 
     
    RETURNS NVARCHAR(MAX) 
    AS 
    BEGIN 
        DECLARE @Start INT, 
                @End INT, 
                @Length INT 
         
        WHILE CHARINDEX('<', @String) > 0 AND CHARINDEX('>', @String, CHARINDEX('<', @String)) > 0 
        BEGIN 
            SELECT  @Start  = CHARINDEX('<', @String),  
                    @End    = CHARINDEX('>', @String, CHARINDEX('<', @String)) 
            SELECT @Length = (@End - @Start) + 1 
             
            IF @Length > 0 
            BEGIN 
                SELECT @String = STUFF(@String, @Start, @Length, '') 
             END 
         END 

        RETURN @String 
    END
GO
/****** Object:  UserDefinedFunction [dbo].[uspClearHTMLTags]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [dbo].[uspClearHTMLTags] 
    (@String NVARCHAR(MAX)) 

    RETURNS NVARCHAR(MAX) 
    AS 
    BEGIN 
        DECLARE @Start INT, 
                @End INT, 
                @Length INT 

        WHILE CHARINDEX('<', @String) > 0 AND CHARINDEX('>', @String, CHARINDEX('<', @String)) > 0 
        BEGIN 
            SELECT  @Start  = CHARINDEX('<', @String),  
                    @End    = CHARINDEX('>', @String, CHARINDEX('<', @String)) 
            SELECT @Length = (@End - @Start) + 1 

            IF @Length > 0 
            BEGIN 
                SELECT @String = STUFF(@String, @Start, @Length, '') 
             END 
         END 

        RETURN @String 
    END
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetJobDataQuery]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnGetJobDataQuery]
(	
)
RETURNS TABLE 
AS
RETURN 
(
	select j.JobNumber,j.FromDate,j.ToDate,j.MediumID,m.Medium, t.ThemeName,
	--a.AdvertisingLine,
	replace(replace(replace(a.AdvertisingLine,char(13),'#'),char(9),''),char(10),'') as AdvertisingLine,
	a.PageNo,a.ItemNo,a.ElementName  ,
	m.MediumCode,t.ThemeID

	from Job j
	inner join Medium m on j.MediumID = m.MeduimID
	inner join Campaign c on j.CampaignID = c.CampaignID
	inner join Theme t on c.ThemeID = t.ThemeID
	inner join Advertising a on a.JobID = j.JobID
	where ((j.FromDate between getdate()-2  and getdate()+2)
or (j.todate between getdate()-2  and getdate()+2))
or ((j.FromDate <= getdate()-2 and j.todate >= getdate() +2))  

)
GO
/****** Object:  View [dbo].[PreApprovedArticleSearchForExclusionMedium]    Script Date: 2022/08/26 08:43:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE VIEW [dbo].[PreApprovedArticleSearchForExclusionMedium] AS
	SELECT DISTINCT RTRIM(LTRIM(STR(ac.Article))) + ' ' + ac.ArticleDesc [ArticleName]
         , ac.Article [MasterItem]
    	 , ac.GTIN [Barcode]
    	 , ac.MdseCat [Category]
		 , ch.DivsnEMailAddress
		 , ch.SnrBuyEMailAddress
		 , ch.BuyerEMailAddress
    FROM dbo.PR_ArticleCategory ac
    INNER JOIN dbo.PR_CategoryHierarchy ch
      ON ch.BuyerMdseCatgry = ac.MdseCat
    INNER JOIN dbo.PR_PreApprovedArticles paa
      ON paa.Article = ac.Article
GO
