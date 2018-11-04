<#	
	.NOTES
	===========================================================================
	 Created on:   	3/28/2018 5:13 PM
	 Created by:   	J Ryan Wall
	 Organization: 	HCCSC
	 Filename:     	invoke-MDTMonitor.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

$URL = "http://MDT01:9801/MDTMonitorData/Computers"

function GetMDTData {
	$Data = Invoke-RestMethod $URL
	
	foreach ($property in ($Data.content.properties)) {
		New-Object PSObject -Property @{
			Name				   = $($property.Name);
			PercentComplete	       = $($property.PercentComplete.'#text');
			Warnings			   = $($property.Warnings.'#text');
			Errors				   = $($property.Errors.'#text');
			DeploymentStatus	   = $(
				Switch ($property.DeploymentStatus.'#text') {
					1 { "Active/Running" }
					2 { "Failed" }
					3 { "Successfully completed" }
					Default { "Unknown" }
				}
			);
			StartTime			   = $($property.StartTime.'#text') -replace "T", " ";
			EndTime			       = $($property.EndTime.'#text') -replace "T", " ";
		}
	}
}

$Head = "<style>"
$Head = $Head + "BODY{background-color:#ffffff;}"
$Head = $Head + "TABLE{border-width: 2px;border-style: solid;border-color: black;border-collapse: collapse;}"
$Head = $Head + "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:#ffffff}"
$Head = $Head + "TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black}"
$Head = $Head + "</style>"
$Body = @"

<hr>
<b>Page refreshes every 5 minutes</b>
<META HTTP-EQUIV="refresh" CONTENT="300">
"@
$Title = "HECC Deployment Status"

$Output = GetMDTData | Select-Object Name, DeploymentStatus, PercentComplete, Warnings, Errors, StartTime, EndTime | Sort-Object -Property StartTime -Descending |`
ConvertTo-Html -Title $Title  `
			   -Head $Head  `
			   -Body $Body  `
			   -PreContent "<H2>Deployment Status for: $ENV:COMPUTERNAME </H2><P>Generated by Power of the Shell</P>"  `
			   -PostContent "<P>This page was last refreshed $((Get-Date).ToString())</P>"  `
			   -Property Name, DeploymentStatus, PercentComplete, Warnings, Errors, StartTime, EndTime


$OutPutMod = $Output | ForEach-Object{
	if ($_ -like "*<td>Successfully completed</td>*") { $_ -replace "<tr>", "<tr bgcolor=lightgreen>" } elseif ($_ -like "*<td>Failed</td>*") { $_ -replace "<tr>", "<tr bgcolor=lightred>" } else { $_ }
}

$OutputMod > 'C:\inetpub\wwwroot\mdt.html'