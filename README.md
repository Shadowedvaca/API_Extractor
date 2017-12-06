# API_Extractor
Powershell script that extracts data from APIs and puts it into a pre-defined table structure in SQL.

# Setup
- Update the following files
    - Database_Deployment_Script.ps1
        - Populate your server name for SQL Server
    - ExtractData.ps1
        - Populate your server name for SQL Server
    - 03_Integration_Setup.sql
         - If you want to use the example extraction for Bonusly, you need to enter your Authorization token in both places indicated in here.
- Download the files
- Run the Database_Deployment_Script, this will create the database, schema and tables and populate them with a sample API.

# To Run
Execute the ExtractData script.  Currently, it will run everything in the API Extraction database.

# Future List
- Supporting data lake extractions
- Targeted Runs
- Profiling API Results
- Dynamic Seeking of elements
- Ability to create table structure from API result structure