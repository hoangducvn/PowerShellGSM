<#
#Change your servers settings in C:\Users\%username%\AppData\Roaming\7DaysToDie\Saves\serverconfig.xml
#>

$Name = "7DaysToDie"

#---------------------------------------------------------
# Server Configuration
#---------------------------------------------------------

$ServerDetails = @{
    #Server Configuration
    ConfigFile = "$Env:userprofile\AppData\Roaming\7DaysToDie\Saves\serverconfig.xml"

    #Rcon IP, usually localhost
    ManagementIP = "127.0.0.1"

    #Rcon Port in serverconfig.xml
    ManagementPort = 8081

    #Rcon Password as set in serverconfig.xml nothing is localhost only.
    ManagementPassword = ""

    #Server Log File
    LogFile = "$Env:userprofile\AppData\Roaming\7DaysToDie\Logs\$(Get-TimeStamp).txt"

#---------------------------------------------------------
# Server Installation Details
#---------------------------------------------------------

    #Name of the Server Instance
    Name = $Name

    #Server Installation Path
    Path = ".\servers\$Name"

    #Steam Server App Id
    AppID = 294420

    #Use Beta builds $true or $false
    Beta = $false

    #Name of the Beta Build
    BetaBuild = ""

    #Beta Build Password
    BetaBuildPassword = ""

    #Process name in the task manager
    ProcessName = "7DaysToDieServer"

    #ProjectZomboid64.exe
    Exec = ".\servers\$Name\7DaysToDieServer.exe"

    #Process Priority Realtime, High, Above normal, Normal, Below normal, Low
    UsePriority = $true
    AppPriority = "High"

    <#
    Process Affinity (Core Assignation)
    Core 1 = > 00000001 = > 1
    Core 2 = > 00000010 = > 2
    Core 3 = > 00000100 = > 4
    Core 4 = > 00001000 = > 8
    Core 5 = > 00010000 = > 16
    Core 6 = > 00100000 = > 32
    Core 7 = > 01000000 = > 64
    Core 8 = > 10000000 = > 128
    ----------------------------
    8 Cores = > 11111111 = > 255
    4 Cores = > 00001111 = > 15
    2 Cores = > 00000011 = > 3
    #>

    UseAffinity = $false
    AppAffinity = 15

    #Should the server validate install after installation or update *(recommended)
    Validate = $true
}
#Create the object
$Server = New-Object -TypeName PsObject -Property $ServerDetails

#---------------------------------------------------------
# Backups
#---------------------------------------------------------

$BackupsDetails = @{
    #Do Backups
    Use = $true

    #Backup Folder
    Path = ".\backups\$($Server.Name)"

    #Number of days of backups to keep.
    Days = 7

    #Number of weeks of weekly backups to keep.
    Weeks = 4

    #Folder to include in backup
    Saves = "$Env:userprofile\AppData\Roaming\7DaysToDie"
}
#Create the object
$Backups = New-Object -TypeName PsObject -Property $BackupsDetails

#---------------------------------------------------------
# Restart Warnings (Require RCON, Telnet or WebSocket API)
#---------------------------------------------------------

$WarningsDetails = @{
    #Use Rcon to restart server softly.
    Use = $true

    #What protocol to use : Rcon, Telnet, Websocket
    Protocol = "Telnet"

    #Times at which the servers will warn the players that it is about to restart. (in seconds between each timers)
    Timers = [System.Collections.ArrayList]@(240,50,10) #Total wait time is 240+50+10 = 300 seconds or 5 minutes

    #message that will be sent. % is a wildcard for the timer.
    MessageMin = "The server will restart in % minutes !"

    #message that will be sent. % is a wildcard for the timer.
    MessageSec = "The server will restart in % seconds !"

    #command to send a message.
    CmdMessage = "say"

    #command to save the server
    CmdSave = "saveworld"

    #How long to wait in seconds after the save command is sent.
    SaveDelay = 15

    #command to stop the server
    CmdStop = "shutdown"
}
#Create the object
$Warnings = New-Object -TypeName PsObject -Property $WarningsDetails

#---------------------------------------------------------
# Launch Arguments
#---------------------------------------------------------

#Launch Arguments
$Arguments = @(
    "-logfile $($Server.LogFile) ",
    "-configfile=$($Server.ConfigFile) ",
    "-batchmode ",
    "-nographics ",
    "-dedicated ",
    "-quit"
)
$ArgumentList = $Arguments -join ""

#Server Launcher
$Launcher = $Server.Exec

#---------------------------------------------------------
# Launch Function
#---------------------------------------------------------

function Start-Server {

    Write-ScriptMsg "Port Forward : 26900 in TCP and 26900 to 26903 in UDP to $($Global.InternalIP)"

    #Copy Config File if not created. Do not modify the one in the server directory, it will be overwriten on updates.
    $ConfigFilePath = Split-Path -Path $Server.ConfigFile
    if (-not(Test-Path -Path $ConfigFilePath)){
        New-Item -ItemType "directory" -Path $ConfigFilePath -Force -ErrorAction SilentlyContinue
    }
    If(-not (Test-Path -Path $Server.ConfigFile -PathType "leaf")){
        Copy-Item -Path "$($Server.Path)\serverconfig.xml" -Destination $Server.ConfigFile -Force
    }
    #Start Server
    $App = Start-Process -FilePath $Launcher -WorkingDirectory $Server.Path -ArgumentList $ArgumentList -PassThru

    #Wait to see if the server is stable.
    Start-Sleep -Seconds 10
    if (-not ($App) -or $App.HasExited){
        Write-Warning "Server Failed to launch."
    } else {
        Write-ServerMsg "Server Started."
            # Set the priority and affinity
        if ($Server.UsePriority) {
            $App.PriorityClass = $Server.AppPriority
        }
        if ($Server.UseAffinity){
            $App.ProcessorAffinity = $Server.AppAffinity
        }
    }
}

Export-ModuleMember -Function Start-Server -Variable @("Server","Backups","Warnings")