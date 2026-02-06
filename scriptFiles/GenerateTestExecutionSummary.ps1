# Function to recursively find all test-suite elements with type="TestFixture"
function Get-TestFixtureSuites {
    param (
        [xml]$node,
        [string]$path
    )
    
    $testFixtureSuites = @()
    Write-Output "Get TestFixture"

    # Iterate through the current level's test-suite elements
    foreach ($suite in $node."test-suite") {
        if ($suite.'type' -eq 'TestFixture') {
            Write-Output "TestFixture if"
            # Capture the suite name and path
            $testFixtureSuites += [pscustomobject]@{
                Name = $suite.'name'
                Path = $path + "\" + $suite.'name'
            }
        } else {
            Write-Output "TestFixture else"
            # Recursively search within the nested test-suites
            $nestedSuites = Get-TestFixtureSuites -node $suite -path ($path + "\" + $suite.'name')
            $testFixtureSuites += $nestedSuites
        }
    }
     Write-Output "End Get TestFixture"
    return $testFixtureSuites
}

$sourceDirectory=$args[0]
$buildUrl=$args[1]
$buildName=$args[2]

if (-not (Test-Path $sourceDirectory)) {
    Write-Error "The directory path provided does not exist."
    exit 1
}

Write-Output "Processing directory: $sourceDirectory"

# Initialize variables to hold the combined data and totals
$pipelineName = "Unknown Pipeline"
$environment = "Unknown Environment"
$combinedRows = @()
$htmlCombinedRows = @()
$totalTests = 0
$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0
$baseUrl = ""
$sno = 1
$testStartTime = ""
$testDuration = 0
# Regular expression to extract the base URL
$baseUrlPattern = 'BaseURL: (.+)'

# Find all markdown files in the directory and subdirectories
$markdownFiles = Get-ChildItem -Path $sourceDirectory -Recurse -Filter *.md

Write-Output "Found $($markdownFiles.Count) markdown files"

foreach ($file in $markdownFiles) {
    Write-Output "Processing file: $file.FullName"
    $content = Get-Content $file.FullName
    foreach ($line in $content) {
        # Extract the base URL (only if it's not already set)
        if (-not $baseUrl -and $line -match $baseUrlPattern) {
            $baseUrl = $matches[1]
            Write-Output "BaseURL found: $baseUrl"
        }
    }
}

# Process each NUnit XML file in the directory
$nunitXmlFiles = Get-ChildItem -Path $sourceDirectory -Recurse -Filter *.xml

Write-Output "Found $($nunitXmlFiles.Count) Xml files"

foreach ($file in $nunitXmlFiles) {
    Write-Output "Processing NUnit XML file: $file.FullName"

    # Parse the NUnit XML file
    [xml]$nunitXml = Get-Content $file.FullName
    # Write-Output "nunitXml : "

    $testNode = $nunitXml.SelectSingleNode("//test-run")
    Write-Output "testNode : $($testNode.OuterXml)"

    # Extract details from the NUnit XML
    if (-not $testStartTime) {
        $testStartTime = [datetime]$testNode."start-time"
    }
    Write-Output "testStartTime : $testStartTime"

    $testDuration += [decimal]$testNode."duration"
    $totalTests += [int]$testNode."total"
    $totalPassed += [int]$testNode."passed"
    $totalFailed += [int]$testNode."failed"
    $totalSkipped += [int]$testNode."skipped"

    Write-Output "testDuration : $testDuration"
    Write-Output "totalTests : $totalTests"
    Write-Output "totalPassed : $totalPassed"
    Write-Output "totalFailed : $totalFailed"
    Write-Output "totalSkipped : $totalSkipped"

    # For markdown
    # $suiteName = $nunitXml.testsuites.testsuite."@name"
    # $combinedRows += "| $($sno++) | $suiteName | $totalTests | $totalPassed | $totalFailed | $totalSkipped |"

    # For HTML
    # $htmlLine = "<tr><td>$($sno-1)</td><td>$suiteName</td><td>$totalTests</td><td>$totalPassed</td><td>$totalFailed</td><td>$totalSkipped</td></tr>"
    # $htmlCombinedRows += $htmlLine

     # Navigate to the correct test-suite element
    #$testSuites = $testNode."test-suite"."test-suite" | Where-Object { $_."@type" -eq "TestFixture" }
    #Write-Output "testSuites : $($testSuites.OuterXml)"

    #foreach ($suite in $testSuites) {
    #    $suiteName = $suite."@name"
    #    
    #    # For markdown
    #    $combinedRows += "| $($sno++) | $suiteName | $totalTests | $totalPassed | $totalFailed | $totalSkipped |"
#
    #    # For HTML
    #    $htmlLine = "<tr><td>$($sno-1)</td><td>$suiteName</td><td>$totalTests</td><td>$totalPassed</td><td>$totalFailed</td><td>$totalSkipped</td></tr>"
    #    $htmlCombinedRows += $htmlLine
    #}

    $testFixtureSuites = Get-TestFixtureSuites -node $testRun -path $testRun.'name'

    # Output all found TestFixture suites
    foreach ($suite in $testFixtureSuites) {
        Write-Output "Test Fixture Suite Found: [string]($suite.Name) at path: [string]($suite.Path)"
    }

}

$passPercentage = [math]::round(($totalPassed / $totalTests) * 100, 2)

Write-Output "passPercentage $(passPercentage)"

# Azure DevOps build link
$buildLink = "${env:SYSTEM_TEAMFOUNDATIONSERVERURI}${env:SYSTEM_TEAMPROJECT}/_build/results?buildId=${env:BUILD_BUILDID}"

# Create the final Markdown content
$finalMdContent = @"
Test Name : $pipelineName
Run Date : $testStartTime
Duration : $testDuration seconds
Environment: $environment


| S.No | Test Suite Name | TotalTests | Passed | Failed | Skipped |
|:----:|-----------------|:----------:|:------:|:------:|:-------:|
"@

# Add combined rows to markdown
$finalMdContent += $combinedRows -join "`n"

# Add the combined totals
$finalMdContent += "`n| * | **Total** | $totalTests | $totalPassed | $totalFailed | $totalSkipped |`n"

# Ensure the Final directory exists
$finalDirectory = Join-Path $sourceDirectory 'Final'
if (-not (Test-Path $finalDirectory)) {
    New-Item -Path $finalDirectory -ItemType Directory | Out-Null
    Write-Output "Created directory: $finalDirectory"
}


# Write the final content to the markdown file
$finalMdPath = Join-Path $finalDirectory 'TestExecutionSummary.md'
$finalMdContent | Out-File -FilePath $finalDirectory -Encoding utf8

Write-Output "Generated markdown summary report at $finalMdPath"

# Create the final HTML content for the email
$finalHtmlContent = @"
<p>Hi,</p>
<p>Test automation scripts execution completed. Find the results summary below.</p>
<p><b>Test Run Details:</b><br>
Test Name : $pipelineName<br>
Run Date  : $testStartTime<br>
Duration  : $testDuration seconds<br>
Environment: $environment<br>
<a href='$buildLink'>Build Link</a>
</p>
<p><b>Suite Summary:</b></p>
<table border='1'>
<tr><th>S.No</th><th>Test Suite Name</th><th>Total Tests</th><th>Passed</th><th>Failed</th><th>Skipped</th></tr>
"@

# Add combined HTML rows to the email content
$finalHtmlContent += $htmlCombinedRows -join "`n"

# Add the combined totals to the email content
$finalHtmlContent += "</table><br><p><b>Totals:</b><br>Total Tests: $totalTests<br>Total Passed: $totalPassed<br>Total Failed: $totalFailed<br>Total Skipped: $totalSkipped<br>Pass Percentage: $passPercentage%</p>"
$finalHtmlContent += "<br><p>Thanks,<br>Test Automation Team</p>"

# Write the final content to the HTML file
$finalHtmlPath = Join-Path $finalDirectory 'TestEmailReport.html'
$finalHtmlContent | Out-File -FilePath $finalHtmlPath -Encoding utf8

Write-Output "Generated HTML email report at $finalHtmlPath"


