:: © 2025 FJBO
::
:: Downloads and installs Git for Windows

@ECHO off

SET "UserDownloads=%USERPROFILE%\Downloads"

SET "GitInstallerFileName=Git-2.50.1-64-bit.exe"
SET "GitInstallerUrl=https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/%GitInstallerFileName%"
SET "GitLocalInstaller=%UserDownloads%\%GitInstallerFileName%"

:: Download Git for Windows
CURL -L -o %GitLocalInstaller% %GitInstallerUrl%

:: Install Git for Windows
%GitLocalInstaller% /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS