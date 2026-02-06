# Set the path to the directory containing the MD files
 #'$(System.ArtifactsDirectory)'
$sourceDirectory=$args[0]
$buildUrl=$args[1]
$buildName=$args[2]
$buildEnv=$args[3]

if (-not (Test-Path $sourceDirectory)) {
    Write-Error "The directory path provided does not exist."
    exit 1
}

Write-Output "Processing directory: $sourceDirectory"

# Initialize variables to hold the combined data and totals
$combinedRows = @()
$htmlCombinedRows = @()

$testStartTime = ""
$testDuration = 0

$totalTests = 0
$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0
$baseUrl = ""
$sno = 1

# Regular expression to extract the base URL
$baseUrlPattern = 'BaseURL: (.+)'

# Find all markdown files in the directory and subdirectories
$markdownFiles = Get-ChildItem -Path $sourceDirectory -Recurse -Filter *.md

Write-Output "Found $($markdownFiles.Count) markdown files"

# Process each file
foreach ($file in $markdownFiles) {
    Write-Output "Processing file: $file.FullName"
    $content = Get-Content $file.FullName
    foreach ($line in $content) {
        # Extract the base URL (only if it's not already set)
        if (-not $baseUrl -and $line -match $baseUrlPattern) {
            $baseUrl = $matches[1]
            Write-Output "BaseURL found: $baseUrl"
        }
        # Extract table rows
        if ($line -match '^\|\s*\d+') {
            # Replace the S.No with the current counter value
            # $line = $line -replace '^\|\s*\d+', ("| {0:D2}" -f $sno)
            # $sno++
            # $combinedRows += $line

            # Replace the S.No with the current counter value in Markdown
            $mdLine = $line -replace '^\|\s*\d+', ("| {0:D2}" -f $sno)
            $combinedRows += $mdLine

            $mdLine = $mdLine.Trim()

            $htmlLine = $mdLine -replace '^\|\s*\d+\s*\|', "<tr><td>$sno</td><td>" `
                     -replace '\|', "</td><td>" `
                     -replace '</td><td>\s*$', "</td></tr>"


            # Split the string by '<td>'
            $htmlLineParts = $htmlLine -split '<td>'

            # Initialize an empty string to store the final result
            $formatHtmlLine = ""

            # Iterate over the split parts
            for ($i = 0; $i -lt $htmlLineParts.Count; $i++) {
                
                 if ($i -eq 2) {
                    # For the second column (index 2), add the left alignment
                    $formatHtmlLine += '<td style="text-align:left;">' + $htmlLineParts[$i]
                } elseif ($i -gt 0) {
                    # For all other occurrences except the first part, add the center alignment
                    $formatHtmlLine += '<td style="text-align:center;">' + $htmlLineParts[$i]
                } else {
                    # For the first part, just append it (before the first <td>)
                    $formatHtmlLine += $htmlLineParts[$i]
                }
            }

            # Now $finalHtmlLine contains the final processed HTML line
            $htmlLine = $formatHtmlLine

            Write-Output "htmlLine row: $htmlLine"                    
            $htmlCombinedRows += $htmlLine

            $sno++

            Write-Output "Added row: $line"
        }
        # Extract and accumulate totals
        if ($line -match '^\|\s*\*\s*\|\s*<div') {
            $totals = [regex]::Matches($line, '\d+')
            $totalTests += [int]$totals[0].Value
            $totalPassed += [int]$totals[1].Value
            $totalFailed += [int]$totals[2].Value
            $totalSkipped += [int]$totals[3].Value
            Write-Output "Updated totals: Tests=$totalTests, Passed=$totalPassed, Failed=$totalFailed, Skipped=$totalSkipped"
        }
    }
    Write-Output "row: $combinedRows"
}


# Create the final markdown content
$finalMdContent = @"
```
BaseURL: $baseUrl
```

| S.No | Test Suite Name | TotalTests | Passed | Failed | Skipped |
|:------:|----------------|:-------------:|:--------:|:--------:|:---------:|`n
"@

# Add combined rows
$finalMdContent += $combinedRows -join "`n"

# Add the combined totals
$finalMdContent += "`n| * | <div align='center'>**Total**</div> | $totalTests | $totalPassed | $totalFailed | $totalSkipped |`n"

# Check if error.txt exists and append its content to the final markdown
$errorFilePath = Join-Path -Path $sourceDirectory -ChildPath 'Final\error.txt'
if (Test-Path $errorFilePath) {
    Write-Output "Error file exist"
    $finalMdContent += "`r`n`r`n`r`n<font color='red'>**Merge Report Error List:-** </font>`r`n"
    $finalMdContent += "The following files encountered errors during the generation of the final merged html report.`r`n"
    $finalMdContent += "Please download and review the individual reports.`r`n`r`n"

    $errorContent = Get-Content $errorFilePath
    foreach ($errorLine in $errorContent) {
        $finalMdContent += " * $errorLine`r`n"
    }
}

Write-Output "finalMdContent: $finalMdContent"

# Ensure the Final directory exists
$finalDirectory = Join-Path $sourceDirectory 'Final'
if (-not (Test-Path $finalDirectory)) {
    New-Item -Path $finalDirectory -ItemType Directory | Out-Null
    Write-Output "Created directory: $finalDirectory"
}

# Write the final content to the Final markdown file
$finalMdPath = Join-Path $finalDirectory 'TestExecutionSummary.md'
$finalMdContent | Out-File -FilePath $finalMdPath -Encoding utf8

Write-Output "Merged markdown file 'TestExecutionSummary.md' created successfully at $finalMdPath."

Write-Host "##vso[task.uploadsummary]$finalMdPath"

# Process each NUnit XML file in the directory
$nunitXmlFiles = Get-ChildItem -Path $sourceDirectory -Recurse -Filter *.xml

$earliestStartTime = [datetime]::MaxValue
$latestEndTime = [datetime]::MinValue

foreach ($file in $nunitXmlFiles) {
    
    [xml]$xmlContent = Get-Content $file.FullName

    # Accessing the 'end-time' attribute using SelectSingleNode
    $testNode = $xmlContent.SelectSingleNode("//test-run")
    
    $testStartTime = [datetime]$testNode."start-time"
    # Compare with the earliest start time found so far
    if ($testStartTime -lt $earliestStartTime) {
        $earliestStartTime = $testStartTime
    }

    $endTime = [datetime]$testNode."end-time"

    if ($endTime -gt $latestEndTime) {
        $latestEndTime = $endTime
    }
}
# Calculate the duration
$duration = $latestEndTime - $earliestStartTime
$formattedDuration = $duration.ToString("hh\:mm\:ss")

# Convert the earliest start time to Mountain Standard Time (MST) or Mountain Daylight Time (MDT)
$mstZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Mountain Standard Time")
$mstTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($earliestStartTime.ToUniversalTime(), $mstZone)

# Format the MST/MDT start time to the desired format
$formattedStartTimeMST = $mstTime.ToString("ddd MMM dd yyyy HH:mm:ss")

# Determine if DST is in effect and set the time zone abbreviation
$timeZoneAbbreviation = if ($mstZone.IsDaylightSavingTime($mstTime)) { "MDT" } else { "MST" }

$formattedStartTimeMST = "$formattedStartTimeMST $timeZoneAbbreviation"

Write-Output "Earliest Start Time: $earliestStartTime"
Write-Output "formatted Earliest Start Time (MST): $formattedStartTimeMST"
Write-Output "Latest End Time: $latestEndTime"
Write-Output "Duration (hrs:min:sec): $formattedDuration"

$passPercentage = [math]::round(($totalPassed / $totalTests) * 100, 2)
Write-Host "##vso[task.setvariable variable=passPercentage;]$passPercentage"

# Create the final HTML content
$finalHtmlContent = @"
<p>Hi,</p>
<p>Test automation script execution is completed. Please find the results summary below.</p>
<p><b><u>Test Run Details</u></b><br>
Test Name : $buildName<br>
Run Date  : $formattedStartTimeMST<br>
Duration (hh:mm:ss) : $formattedDuration<br>
Environment: $buildEnv<br>
BaseUrl: $baseUrl<br>
Pass Percentage: $passPercentage%
</p>
<p><b>Test Execution Summary:</b></p>
<table border='1'>
<tr style="background-color: #D3D3D3">
<th style='text-align:center;'> S.No </th>
<th style='text-align:center;'> Test Suite Name </th>
<th style='text-align:center;'> TotalTests </th>
<th style='text-align:center;'> Passed </th>
<th style='text-align:center;'> Failed </th>
<th style='text-align:center;'> Skipped </th>
</tr>
"@

# Append combined HTML rows
$finalHtmlContent += ($htmlCombinedRows -join "`n")

# Add the combined totals
$finalHtmlContent += "<tr><td style='text-align:center;' colspan='2'><b>Totals</b></td><td style='text-align:center;'>$totalTests</td><td style='text-align:center;'>$totalPassed</td><td style='text-align:center;'>$totalFailed</td><td style='text-align:center;'>$totalSkipped</td></tr>"
$finalHtmlContent += "</table><br>"
$finalHtmlContent += "<a href='$buildUrl'>Click this link to navigate to the build pipeline and review the test results in detail</a>"
$finalHtmlContent += "<br><p>Thanks,<br>Test Automation Team</p>"

# Write the final content to an HTML file
$finalHtmlPath = Join-Path $finalDirectory 'TestEmailReport.html'
$finalHtmlContent | Out-File -FilePath $finalHtmlPath -Encoding utf8

Write-Output "Generated HTML report at $finalHtmlPath"

# Return the path of the generated HTML report
return $finalHtmlPath
