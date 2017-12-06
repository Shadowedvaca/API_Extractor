USE API_Extractions;

GO

TRUNCATE TABLE dbo.Vendors;

GO

INSERT INTO dbo.Vendors ( VendorName, ETLScriptSQL )
VALUES ( 'Bonusly', 'N/A' );

GO

TRUNCATE TABLE dbo.APIs;

GO

INSERT INTO dbo.APIs ( VendorID, APIName, APIString, APIReturnLimit, ObjectToCount, SkipParamName )
VALUES
	( 1, 'Bonuses', 'https://bonus.ly/api/v1/bonuses?', 100, 'result', '&skip=' )
	, ( 1, 'Users', 'https://bonus.ly/api/v1/users?', 100, 'result', '&skip=' )
	, ( 1, 'Company', 'https://bonus.ly/api/v1/companies/show?', 0, 'result', '' )
	, ( 1, 'Rewards', 'https://bonus.ly/api/v1/rewards?', 0, 'result', '' );

GO

TRUNCATE TABLE dbo.Headers;

GO

INSERT INTO dbo.Headers ( HeaderName, HeaderValue )
VALUES ( 'Authorization', 'ENTER_YOUR_TOKEN_HERE' );

GO

TRUNCATE TABLE dbo.APIHeaders;

GO

INSERT INTO dbo.APIHeaders ( APIID, HeaderID )
VALUES ( 1, 1 ), ( 2, 1 ), ( 3, 1 ), ( 4, 1 );

GO

TRUNCATE TABLE dbo.Params;

GO

INSERT INTO dbo.Params ( ParamName, ParamValueType, ParamValue )
VALUES
	( 'access_token', 'value', 'ENTER_YOUR_TOKEN_HERE' )
	,( '&limit', 'value', '100' ) 
	,( '&include_children', 'value', 'true' )
	,( '&start_time', 'code', '([datetime]"2016-07-20").GetDateTimeFormats("s")' )
	,( '&end_time', 'code', '(Get-Date).GetDateTimeFormats("s")' )
	,( '&include_archived', 'value', 'true' )
	,( '&show_financial_data', 'value', 'true' );

GO

TRUNCATE TABLE dbo.APIParams;

GO

INSERT INTO dbo.APIParams ( APIID, ParamID )
VALUES ( 1, 1 ), ( 1, 2 ), ( 1, 3 ), ( 1, 4 ), ( 1, 5 ), ( 2, 6 ), ( 2, 7 ), ( 2, 1 ), ( 2, 2 ), ( 3, 1 ), ( 4, 1 );

GO

TRUNCATE TABLE dbo.Integrations;

GO

INSERT INTO dbo.Integrations ( APIID, IntegrationName, DatabaseName, TableName )
VALUES
	( 1, 'Parent Bonuses', 'API_Extractions', 'bly.Bonuses' )
	, ( 1, 'Parent Givers', 'API_Extractions', 'bly.BonusUsersGivers' )
	, ( 1, 'Parent Receivers', 'API_Extractions', 'bly.BonusUsersReceivers' )
	, ( 1, 'Child Bonuses', 'API_Extractions', 'bly.Bonuses' )
	, ( 1, 'Child Givers', 'API_Extractions', 'bly.BonusUsersGivers' )
	, ( 1, 'Child Receivers', 'API_Extractions', 'bly.BonusUsersReceivers' )
	, ( 2, 'Users', 'API_Extractions', 'bly.Users' )
	, ( 3, 'Company Hashtags', 'API_Extractions', 'bly.HashtagsCompany' )
	, ( 3, 'Suggested Hashtags', 'API_Extractions', 'bly.HashtagsSuggested' )
	, ( 3, 'Trending Hashtags', 'API_Extractions', 'bly.HashtagsTrending' )
	, ( 4, 'Rewards', 'API_Extractions', 'bly.Rewards' );

GO

TRUNCATE TABLE dbo.IntegrationLevels;

GO

INSERT INTO dbo.IntegrationLevels ( IntegrationID, LevelID, LevelName )
VALUES
	( 1, 0, '' ), ( 1, 1, 'result' )
	, ( 2, 0, '' ), ( 2, 1, 'result' ), ( 2, 2, 'giver' )
	, ( 3, 0, '' ), ( 3, 1, 'result' ), ( 3, 2, 'receivers' )
	, ( 4, 0, '' ), ( 4, 1, 'result' ), ( 4, 2, 'child_bonuses' )
	, ( 5, 0, '' ), ( 5, 1, 'result' ), ( 5, 2, 'child_bonuses' ), ( 5, 3, 'giver' )
	, ( 6, 0, '' ), ( 6, 1, 'result' ), ( 6, 2, 'child_bonuses' ), ( 6, 3, 'receivers' )
	, ( 7, 0, '' ), ( 7, 1, 'result' )
	, ( 8, 0, '' ), ( 8, 1, 'result' ), ( 8, 2, 'company_hashtags' )
	, ( 9, 0, '' ), ( 9, 1, 'result' ), ( 9, 2, 'suggested_hashtags' )
	, ( 10, 0, '' ), ( 10, 1, 'result' ), ( 10, 2, 'trending_hashtags' )
	, ( 11, 0, '' ), ( 11, 1, 'result' ), ( 11, 2, 'rewards' ), ( 11, 3, 'denominations' );

GO

TRUNCATE TABLE dbo.IntegrationMappings;

GO

INSERT INTO dbo.IntegrationMappings ( IntegrationID, ColumnName, LevelID, KeyName )
VALUES
	( 1, 'id', 1, 'id' )
	,( 1, 'created_at', 1, 'created_at' )
	,( 1, 'reason', 1, 'reason' )
	,( 1, 'reason_html', 1, 'reason_html' )
	,( 1, 'amount', 1, 'amount' )
	,( 1, 'amount_with_currency', 1, 'amount_with_currency' )
	,( 1, 'value', 1, 'value' )
	,( 1, 'via', 1, 'via' )
	,( 1, 'family_amount', 1, 'family_amount' )
	,( 2, 'bonus_id', 1, 'id' )
	,( 2, 'user_id', 2, 'id' )
	,( 3, 'bonus_id', 1, 'id' )
	,( 3, 'user_id', 2, 'id' )
	,( 4, 'id', 2, 'id' )
	,( 4, 'created_at', 2, 'created_at' )
	,( 4, 'reason', 2, 'reason' )
	,( 4, 'reason_html', 2, 'reason_html' )
	,( 4, 'amount', 2, 'amount' )
	,( 4, 'amount_with_currency', 2, 'amount_with_currency' )
	,( 4, 'value', 2, 'value' )
	,( 4, 'via', 2, 'via' )
	,( 4, 'family_amount', 2, 'family_amount' )
	,( 5, 'bonus_id', 2, 'id' )
	,( 5, 'user_id', 3, 'id' )
	,( 6, 'bonus_id', 2, 'id' )
	,( 6, 'user_id', 3, 'id' )
	,( 7, 'id', 1, 'id' )
	,( 7, 'short_name', 1, 'short_name' )
	,( 7, 'display_name', 1, 'display_name' )
	,( 7, 'username', 1, 'username' )
	,( 7, 'email', 1, 'email' )
	,( 7, 'path', 1, 'path' )
	,( 7, 'full_pic_url', 1, 'full_pic_url' )
	,( 7, 'profile_pic_url', 1, 'profile_pic_url' )
	,( 7, 'first_name', 1, 'first_name' )
	,( 7, 'last_name', 1, 'last_name' )
	,( 7, 'created_at', 1, 'created_at' )
	,( 7, 'last_active_at', 1, 'last_active_at' )
	,( 7, 'external_unique_id', 1, 'external_unique_id' )
	,( 7, 'budget_boost', 1, 'budget_boost' )
	,( 7, 'user_mode', 1, 'user_mode' )
	,( 7, 'country', 1, 'country' )
	,( 7, 'time_zone', 1, 'time_zone' )
	,( 7, 'can_give', 1, 'can_give' )
	,( 7, 'can_receive', 1, 'can_receive' )
	,( 7, 'status', 1, 'status' )
	,( 7, 'department', 1, 'department' )
	,( 7, 'location', 1, 'location' )
	,( 8, 'hashtag', 2, 'Array_Value' )
	,( 9, 'hashtag', 2, 'Array_Value' )
	,( 10, 'hashtag', 2, 'Array_Value' )
	,( 11, 'id', 3, 'id' )
	,( 11, 'type', 1, 'type' )
	,( 11, 'type_name', 1, 'name' )
	,( 11, 'reward_name', 2, 'name' )
	,( 11, 'image_url', 2, 'image_url' )
	,( 11, 'minimum_display_price', 2, 'minimum_display_price' )
	,( 11, 'description_text', 2, 'description.text' )
	,( 11, 'description_html', 2, 'description.html' )
	,( 11, 'disclaimer_html', 2, 'disclaimer_html' )
	,( 11, 'warning', 2, 'warning' )
	,( 11, 'denomination_name', 3, 'name' )
	,( 11, 'price', 3, 'price' )
	,( 11, 'display_price', 3, 'display_price' )
	,( 11, 'available', 3, 'available' );

GO
