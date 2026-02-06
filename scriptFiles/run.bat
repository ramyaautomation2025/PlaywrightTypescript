REM Assign arguments to variables
set environmentToRun=%~1
set versionToRun=%~2
set testMainTagName=%~3
set testSubTagName=%~4

REM Construct the dotnet test command with the provided arguments
set testRunParams=environment="%environmentToRun%" version="%versionToRun%" testcategory="%testMainTagName%" testsubcategory="%testSubTagName%"

echo %testRunParams%

REM Run the tests with the specified results directory
REM dotnet test --settings DCBankAutomation\dcbank.runsettings --logger "console;verbosity=detailed" --logger "nunit;LogFilePath=%TEST_RESULTS_DIR%\nunit-xml\dcb.xml" -- %testRunParams%

dotnet run --project DCBankAutomation\DCBankAutomation.csproj --no-restore /p:WarningLevel=0 -- %testRunParams%