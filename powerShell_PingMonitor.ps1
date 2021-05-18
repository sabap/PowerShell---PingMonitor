Clear-Host
$Global:ScriptRunTimeStart = (Get-Date)
$MonitorAddresses = @(
# Set the server names and IPs that you want to monitor (Names cannot have spaces).
# MUST have a space between the Server Name and IP Address, both continated with double-quotes, ended with a comma (NO comma on last entry)
# Example: ["VM-SERVER-01 192.168.0.2",]
"VM-SERVER-01 192.168.0.2",
"VM-SERVER-02 192.168.0.3",
"VM-SERVER-03 192.168.0.4",
"VM-SERVER-04 192.168.0.5"
)
$PingSourceComputer = "VM-SERVER-000.MyDomain.local" # ----- Set the computer from which the pings will be transmitted. This can be different than the computer that is running the script.
$FailMinutes = "5" # ------ Set the number of minutes a continuous failure occurs before executing the SendMail function (Example "5")
$Global:NotificationMinutes = "120" # ------ Set the sleep time for additional notifications. (Example "60")
# -----  START SEND MAIL VARIABLES -----
$Global:EmailFromAddress = "MyEmailAddress@gmail.com" # This is the FROM address that will appear in the email. If you are using Gmail SMTP, this will need to be the account's email address.
$Global:EmailSMTPServer = "smtp.gmail.com"  # This is the SMTP server for the email function (Example: smtp.gmail.com).
$Global:SMTPPort = "587" # This is the SMTP server's SSL port
$Global:EmailSubject = "Ping monitor **FAILURE DETECTED**" # Default Email Subject
$Global:EmailToRecipient = "NoReply@SomeAddress.com" # Use this as the main email address. IN the case of multiple recipients, leave this one as generic and place others in teh BCC variable below
$Global:EmailBCCRecipients = "Recipient1@SomeEmailDomain.com","Recipient2@SomeEmailDomain.com" # In the case of multiple recipients, Use the BCC, so everyone does not show in the list. Multiple addresses in quotes separated by comma.
$Global:EmailCredentials = (Get-Credential)  # This will prompt you for your email server's credentials upon executio of the script.
# ----------- DECLARE EMAIL FUNCTION ------------------------------------------
Function EmailAdmin 
    {
    $TotalScriptRuntime = (Get-Date) - $Global:ScriptRunTimeStart
    $Minutes = $TotalScriptRuntime.Minutes
    $Seconds = $TotalScriptRuntime.Seconds
    $Hours = $TotalScriptRuntime.Hours
    $Days = $TotalScriptRuntime.Days

    IF($TotalScriptRuntime.Minutes -eq 1){$MinuteAdjective = "Minute"}
    Else{$MinuteAdjective = "Minutes"}
    
    IF($TotalScriptRuntime.Seconds -eq 1){$SecondAdjective = "Second"}
    Else{$SecondAdjective = "Seconds"}

    IF($TotalScriptRuntime.Hours -eq 1){$HourAdjective = "Hour"}
    Else{$HourAdjective = "Hours"}

    IF($TotalScriptRuntime.Days -eq 1){$DayAdjective = "Day"}
    Else{$DayAdjective = "Days"}
    
    $RuntimeMessage = "$Days $DayAdjective, $Hours $HourAdjective, $Minutes $MinuteAdjective and $Seconds $SecondAdjective"

    
    ## START ADMIN SEND MAIL FUNCTION  |  ONLY edit if you are comfortable with HTML. Body lines CANNOT be indented or begin with whitespace.
    $MailBody = 
@"
Greetings from Information Services,</br>
Your Ping Monitor has indicated a failure for server [<b>$Global:ServerName</b>]</br>
Pings have failed for <font color="red"><b>$Global:TotalDownTime</b></font> minutes.</br>
<hr>
<i>Note: The script will keep running until manually stopped.  Notifications will be suppressed for $Global:NotificationMinutes minutes.</i></br>
<hr>
<b>Total Script run time</b></br>
$RuntimeMessage</br>
</br>
Best Regards,</br>
<i>Script written by: Matt Elsberry</i></br>
This script was executed from <b>$env:computername</b> by <b>$env:UserName</b></br>
"@
    Send-MailMessage -Body $MailBody -BodyAsHtml `
    -From $Global:EmailFromAddress -To $Global:EmailToRecipient -Bcc $Global:EmailBCCRecipients `
    -Subject $Global:EmailSubject -Encoding $([System.Text.Encoding]::UTF8) `
    -SmtpServer $Global:EmailSMTPServer -Credential $Global:EmailCredentials `
    -port $Global:SMTPPort -UseSsl
    #Exit  #------ Remove the "#" at the beginning of this line if you want the script to stop after the 1st email is sent.
    }
# ----------- END EMAIL FUNCTION ------------------------------------------
ForEach ($Server in $MonitorAddresses)
    {
    $ServerName,$ServerIP = $Server.split(" ")
    New-Variable -Name "Fail$ServerName" -Value 0 -Force
    New-Variable -Name "FailSwitch$ServerName" -Value $false -Force
    New-Variable -Name "FailStartTime$ServerName" -Value "blank" -Force    
    New-Variable -Name "FailNotificationTime$ServerName" -Value "blank" -Force
    }
Do {
Start-Sleep 4
ForEach ($Server in $MonitorAddresses)
    {
    $ServerName,$ServerIP = $Server.split(" ")        
    $Results = Test-Connection -Source $PingSourceComputer -ComputerName $ServerIP -Count 1 -ErrorAction Ignore
        IF ($null -eq $Results)
            {
            If ((Get-Variable -Name "FailStartTime$ServerName" -ValueOnly) -eq "blank")
                {
                New-Variable -Name "FailStartTime$ServerName" -Value (Get-Date) -Force                
                }                
            Else {
                IF ((Get-Variable -Name "FailSwitch$ServerName" -ValueOnly) -eq $false)
                    {
                    IF ((Get-Variable -Name "FailStartTime$ServerName" -ValueOnly) -lt (get-date).AddMinutes("-$FailMinutes"))
                        {
                        New-Variable -Name "TotalDownTime$ServerName" -Value ((Get-Date) - (Get-Variable -Name "FailStartTime$ServerName" -ValueOnly)) -Force
                        $Global:TotalDownTime = (Get-Variable -Name "TotalDownTime$ServerName" -ValueOnly)
                        $Global:TotalDownTime = $Global:TotalDownTime.TotalMinutes.ToString("N2")
                        Write-Host "$Server has been down for $Global:TotalDownTime minute(s)"
                        $Global:ServerName = $ServerName
                        New-Variable -Name "FailSwitch$ServerName" -Value $true -Force
                        New-Variable -Name "FailNotificationTime$ServerName" -Value (Get-Date) -Force
                        EmailAdmin
                        }
                    }
                Else { # ------------- If it has been over 30 minutes since the last notification, reset the Fail Switch.
                    If ((Get-Variable -Name "FailNotificationTime$ServerName" -ValueOnly) -lt (get-date).AddMinutes("-$Global:NotificationMinutes"))
                        {New-Variable -Name "FailSwitch$ServerName" -Value $false -Force}
                    }
                }             
            New-Variable -Name "Fail$ServerName" -Value ((Get-Variable -Name "Fail$ServerName" -ValueOnly) + 1) -Force             
            }
        Else {
            # -------------- Resetting the failure triggers on successful ping
            New-Variable -Name "Fail$ServerName" -Value 0 -Force            
            New-Variable -Name "FailStartTime$ServerName" -Value "blank" -Force
            New-Variable -Name "TotalDownTime$ServerName" -Value "" -Force
            New-Variable -Name "FailSwitch$ServerName" -Value $false -Force
            }        
    }    
}While($true)