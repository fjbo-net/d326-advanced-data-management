:: © 2025 FJBO
::
:: Downloads and installs Git for Windows

@ECHO off

SET "UserDownloads=%USERPROFILE%\Downloads"

SET "GitInstallerFileName=Git-2.50.1-64-bit.exe"
SET "GitInstallerUrl=https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/%GitInstallerFileName%"
SET "GitLocalInstaller=%UserDownloads%\%GitInstallerFileName%"

:: Download Git for Windows
ECHO.
ECHO [1/2] Downloading Git for Windows installer...
CURL -L -o %GitLocalInstaller% %GitInstallerUrl%
ECHO SUCCESS: Git for Windows installer has been downloaded
ECHO Installer Location: '%GitLocalInstaller%'

:: Install Git for Windows
ECHO.
ECHO [2/2] Installing Git for Windows...
%GitLocalInstaller% /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS
ECHO SUCCESS: Git for Windows has been installed successfully


:: Success cleanup
ECHO.
ECHO DONE: Git for Windows has been installed successfully!
ECHO.

GOTO :CLEANUP_SUCCESS


:CLEANUP_ERROR
ECHO.
ECHO ERROR: Git for Windows installation could not be completed!
ECHO.


:CLEANUP_SUCCESS
:: Clean up temporary files
IF EXIST "%GitLocalInstaller%" (
	DEL /Q "%GitLocalInstaller%" >nul 2>&1
)

IF DEFINED CLEANUP_ERROR (
	EXIT /B 1
) ELSE (
	EXIT /B 0
)