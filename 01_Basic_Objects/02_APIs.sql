CREATE TABLE dbo.APIs (
	ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	,VendorID INT NOT NULL
	,APIName VARCHAR(50) NOT NULL
	,APIString VARCHAR(1000) NOT NULL
	,APIReturnLimit INT NULL DEFAULT 0
	,ObjectToCount VARCHAR(100) NULL DEFAULT ''
	,SkipParamName VARCHAR(100) NULL DEFAULT ''
)