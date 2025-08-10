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
CURL -L -f -s -o %GitLocalInstaller% %GitInstallerUrl%
IF ERRORLEVEL 1 (
	ECHO ERROR: Failed to download Git for Windows installer.
	GOTO :CLEANUP_ERROR
)

:: Verify Git for Windows installer was downloaded
IF NOT EXIST "%GitLocalInstaller%" (
	ECHO ERROR: Git for Windows installer was not downloaded.
	GOTO :CLEANUP_ERROR
)

ECHO SUCCESS: Git for Windows installer has been downloaded
ECHO Installer Location: '%GitLocalInstaller%'

:: Install Git for Windows
ECHO.
ECHO [2/2] Installing Git for Windows...
START /WAIT /B CMD /C ""%GitLocalInstaller%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS"
IF ERRORLEVEL 1 (
    ECHO ERROR: Git for Windows installation failed
    GOTO :CLEANUP_ERROR
)
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