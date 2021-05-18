# PowerShell---PingMonitor
Ping Monitor with email notifications (PowerShell)

This script will continuously ping multiple IP Addresses from a specified server/computer.  The script does NOT have to be ran on the machine from which you wish to monitor communications. Using the "-source" perameter in the "Test-Connection" command, PowerShell makes it possible to ping hosts from other machines and return the results locally.This comes in handy if you have a agroup of servers that are behind a firewall rule that only allows connectivity to a certain server.  Instead of executing the PoserShell on the specific server, we can ping by proxy!</br>
_Note: View the .PDF for the flowchart of this script's logic._

**Prerequisites:**
1. You will need access to an SMTP relay server (or use Gmail's relay server). Have ready the: SMTP Address, SSL port number & Credentials
2. You need connectivity between the machine that is executing the script and the machine from which you want the pings to originate.
3. PowerShell 5.1+
</br>
   
**SETUP** 
**POWERSHELL SCRIPT**</br>
1. Copy the PowerShell script to your computer (Example: c:\TEMP)</br>
2. Edit lines 7 - 22 of the script to suit your environment.</br>
```
# Set the server names and IPs that you want to monitor (Names cannot have spaces).
# MUST have a space between the Server Name and IP Address, both continated with double-quotes, ended with a comma (NO comma on last entry)
# Example: ["VM-SERVER-01 192.168.0.2",]
"VM-SERVER-01 192.168.0.2",
"VM-SERVER-02 192.168.0.3",
"VM-SERVER-03 192.168.0.4",
"VM-SERVER-04 192.168.0.5"
$PingSourceComputer = "VM-SERVER-000.MyDomain.local" # ----- Set the computer from which the pings will be transmitted. This can be different than the computer that is running the script.
$FailMinutes = "5" # ------ Set the number of minutes a continuous failure occurs before executing the SendMail function (Example "5")
$Global:NotificationMinutes = "120" # ------ Set the sleep time (Minutes) before additional additional notifications are sent. (Example "60") This is per server, not collectively!
$Global:EmailFromAddress = "MyEmailAddress@gmail.com" # This is the FROM address that will appear in the email. If you are using Gmail SMTP, this will need to be the account's email address.
$Global:EmailSMTPServer = "smtp.gmail.com"  # This is the SMTP server for the email function (Example: smtp.gmail.com).
$Global:SMTPPort = "587" # This is the SMTP server's SSL port
$Global:EmailSubject = "Ping monitor **FAILURE DETECTED**" # Default Email Subject
$Global:EmailToRecipient = "NoReply@SomeAddress.com" # Use this as the main email address. IN the case of multiple recipients, leave this one as generic and place others in teh BCC variable below
$Global:EmailBCCRecipients = "Recipient1@SomeEmailDomain.com","Recipient2@SomeEmailDomain.com" # In the case of multiple recipients, Use the BCC, so everyone does not show in the list. Multiple addresses in quotes separated by comma.
$Global:EmailCredentials = (Get-Credential)  # This will prompt you for your email server's credentials upon executio of the script.
```
These are all the changes you need to make.</br>
If you feel comfortable changing the HTML email portion at the bottom, do so to suit your needs.

**EXECUTING THE SCRIPT**</br>
1. When you execute the script, it will prompt for credentials.  These credentials are for the SMTP server authentication.
2. Leave the script running for as long as you wish.

You are now done!</br>

**TROUBLESHOOTING**</br>
If you are not recieving an email after manually running the script, you can open the script in the PowerShell ISE and run it from there.
That will give you any error codes that may arise.

**COMMON ERRORS**</br>
SMTP relay server misconfiguration.</br>
Script-Execution settings (Example: Set-ExecutionPolicy -Unrestricted).</br>
PowerShell may need to be ran as Administrator.</br>

**THINGS TO NOTE**</br>
Every SMTP server has the potential for being different. Port numbers, SSL/TLS, Auth/No-Auth, etc.  If you are having issues with your SMTP not working, a google serch for "PowerShell Send-MailMessage [Your SMTP service]" will most likely yiels the correct varialbe settings to get this working.