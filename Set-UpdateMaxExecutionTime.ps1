# Identifies all updates on the SCCM site server with a Title matching the provied criteria
# For each update it sets the maximum execution time to the minutes specified
# intended to be run daily against the CAS server to fix any new updates the first day they are released
# This was created to avoid the error that may occur when installing a feature update or other large update on a slow computer 

#Swap for testing
#Param([string]$SiteServer="XSNW10W142C",[string]$SiteCode="PP0", [string]$TitleCriteria="Monthly Quality Rollup", [int]$Minutes=240, [string]$InstanceName="SetUpdateMaxExecutionTime")
Param([string]$SiteServer,[string]$SiteCode, [string]$TitleCriteria, [int]$Minutes, [string]$InstanceName)  

Function Log-Append () {
[CmdletBinding()]   
PARAM 
(   [Parameter(Position=1)] $strLogFileName,
    [Parameter(Position=2)] $strLogText )
    
    Write-Host $strLogText
    $strLogText = ($(get-date).tostring()+" ; "+$strLogText.ToString()) 
    Out-File -InputObject $strLogText -FilePath $strLogFileName -Append -NoClobber
}

Function Get-UpdatesByTitle {
    [CmdletBinding()] 
    PARAM  (  [Parameter(Position=1)] $SiteServer,   
              [Parameter(Position=2)] $SiteCode,
              [Parameter(Position=3)] $TitleCriteria  ) 

# Check if the specified name for the source update list exists
$wqlquery = ("SELECT * FROM SMS_SoftwareUpdate WHERE LocalizedDisplayName LIKE '%"+$TitleCriteria+"%' ")
$Updates = Get-WmiObject -ComputerName $SiteServer -Namespace ("root\sms\Site_"+$SiteCode) -Query $WQLQuery 
Return $Updates
}

Function Get-UpdateInfo {
param(   $SiteServer,   
         $SiteCode,
         $Update_CIID )

	$objUpdate = Get-WmiObject -ComputerName $SiteServer -Namespace ("root\sms\Site_"+$SiteCode) -Class "SMS_SoftwareUpdate" -Filter ("CI_ID = "+$Update_CIID) -ErrorAction SilentlyContinue
    if ($objUpdate) { 
        $objUpdate = [wmi]$objUpdate.__PATH  
        Return $objUpdate
    }
    ELSE { Return $Null }
}


############################### MAIN ######################################

#Define constants and initialiaze variables

    $LoggingFolder = "C:\TEMP\WSUSManagement\"
    $TodaysDate = Get-Date 
    $objLogging = @()
    $Updates = @()

# Prompt for SiteServer if missing
If ( !$SiteServer ) { [string]$SiteServer = Read-Host "Enter the  SCCM CAS Site Server Name: " }

# Prompt SiteCode if missing
If ( !$SiteCode ) { [string]$SiteCode = Read-Host "Enter the CAS Site Code: " }

# Prompt for TitleCriteria if missing
If ( !$TitleCriteria ) { [string]$TitleCriteria = Read-Host "Enter the update Title Criteria: " }

# Prompt for Minutes if missing
If ( !$Minutes ) { [int]$Minutes = Read-Host "Enter the number of minutes for maximum execution time: " }
$Minutes = $Minutes * 60

# Set InstanceName to WSUSManagagement if it is missing
If ( !$InstanceName ) { [string]$InstanceName = "SetUpdateMaxExecutionTime" }

# Lookup the SCCM site definition to populate global variables
    $WQLQuery = ("SELECT * FROM sms_sci_sitedefinition WHERE SiteCode = '"+$SiteCode+"'")
    $objSiteDefinition = Get-WmiObject -ComputerName $SiteServer -Namespace ("root\sms\Site_"+$SiteCode) -Query $WQLQuery
    $SCCMDBName = $objSiteDefinition.SQLDatabaseName
    $SQLServer = $objSiteDefinition.SQLServerName

# Prepare Logging       
    If (!(Test-Path $LoggingFolder))  { $Result = New-Item $LoggingFolder -type directory }
    $LogFileName = ($LoggingFolder+$InstanceName+"-"+$TodaysDate.Year+"-"+$TodaysDate.Month.ToString().PadLeft(2,"0")+"-"+$TodaysDate.Day.ToString().PadLeft(2,"0")+".log")
    $LogFileName = $LogFileName.Replace(" ", "")
    Log-Append -strLogFileName $LogFileName -strLogText ("Script started with the following parameters")
    Log-Append -strLogFileName $LogFileName -strLogText ("Paramater SiteServer :      $SiteServer")
    Log-Append -strLogFileName $LogFileName -strLogText ("Paramater SiteCode :        $SiteCode")
    Log-Append -strLogFileName $LogFileName -strLogText ("Paramater Title Criteria :  $TitleCriteria")
    Log-Append -strLogFileName $LogFileName -strLogText ("Paramater Minutes :         $Minutes")

# Load the SCCM DLL
    Log-Append -strLogFileName $LogFileName -strLogText ("Creating an instance of the com object SMSResGen.SMSResGen.1" )
    Try { $SMSDisc = New-Object -ComObject "SMSResGen.SMSResGen.1" }
    Catch {  }

 
# Get the updates whose title matches the title criteria
$Updates = Get-UpdatesByTitle -SiteServer $SiteServer -SiteCode $SiteCode -TitleCriteria "$TitleCriteria"
If ( $Updates )  {
    Log-Append -strLogFileName $LogFileName -strLogText ("Setting the max execution time to "+$Minutes+" minutes." ) 
    ForEach ( $Update in $Updates ) {
        Log-Append -strLogFileName $LogFileName -strLogText ("CIID="+$Update.CI_ID+" ArticleID="+$Update.ArticleID+" Title="+$Update.LocalizedDisplayName ) 
        $CIID=$Update.CI_ID
        $Update['MaxExecutionTime']=$Minutes
        $Result = $Update.Put()
        $VerifyUpdate=Get-UpdateInfo -SiteServer $SiteServer -SiteCode $SiteCode  -Update_CIID $CIID
        If ( $VerifyUpdate.MaxExecutionTime -ne $Minutes ) {
            Log-Append -strLogFileName $LogFileName -strLogText ("Error: Update MaxExecutionTime of "+$VerifyUpdate.MaxExecutionTime/60+" does not equal the specified time of "+$Minutes/60+" minutes.") 
        }
        ELSE {
            Log-Append -strLogFileName $LogFileName -strLogText ("Update MaxExecutionTime of "+$VerifyUpdate.MaxExecutionTime/60+" verified.") 
        }
    }   
}
ELSE { 
    Log-Append -strLogFileName $LogFileName -strLogText ("Could not find any updates matching the criteria " + $TitleCriteria ) 
    Exit
}

Log-Append -strLogFileName $LogFileName -strLogText ("Script complete.")