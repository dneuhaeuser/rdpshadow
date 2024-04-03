# rdpshadow
collection of scripts for initiating RDP shadowing

- rdpshadow-ADclient.bat
  queries active console session of specified host and initiates RDP shadow to this session
  has to be run on a client in same AD with suitable account (e.g. on admin jump host)
  
- rdpshadow-REMclient.bat
  queries active console session of specified host and initiates RDP shadow to this session
  uses specified user/pass to communicate with remote machine
  can be run from a client in different AD for example
  
- rdpshadow-TS.bat
  for admin session use on terminal server
  lists all logged on users on this machine
  initiates RDP shadow to specified session

- rdpshadow_user.ps1
  powershell version
  prompts for remote host and credentials
  queries host for active sessions
  initiates RDP shadow to selected session
