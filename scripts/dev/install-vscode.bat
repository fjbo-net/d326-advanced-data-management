:: © 2025 FJBO
::
:: Downloads and installs Visual Studio Code 

@ECHO off

SET "UserDownloads=%USERPROFILE%\Downloads"

SET "VsCodeInstallerCommit=488a1f239235055e34e673291fb8d8c810886f81"
SET "VsCodeInstallerFileName=VSCodeUserSetup-x64-1.102.3.exe"
SET "VsCodeInstallerUrl=https://vscode.download.prss.microsoft.com/dbazure/download/stable/%VsCodeInstallerCommit%/%VsCodeInstallerFileName%"
SET "VsCodeLocalInstaller=%UserDownloads%\%VsCodeInstallerFileName%"

:: Download Visual Studio Code installer
ECHO.
ECHO [1/2] Downloading Visual Studio Code installer...
CURL -L -f -s -o %VsCodeLocalInstaller% %VsCodeInstallerUrl%
IF ERRORLEVEL 1 (
	ECHO ERROR: Failed to download Visual Studio Code installer.
	GOTO :CLEANUP_ERROR
)

:: Verify Visual Studio Code installer was downloaded
IF NOT EXIST "%VsCodeLocalInstaller%" (
	ECHO ERROR: Visual Studio Code installer was not downloaded.
	GOTO :CLEANUP_ERROR
)

ECHO SUCCESS: Visual Studio Code installer has been downloaded
ECHO Installer Location: '%VsCodeLocalInstaller%'

:: Install Visual Studio Code
ECHO.
ECHO [2/2] Installing Visual Studio Code...
START /WAIT /B CMD /C ""%VsCodeLocalInstaller%" /VERYSILENT /SUPPRESSMSGBOXES /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders""
IF ERRORLEVEL 1 (
    ECHO ERROR: Visual Studio Code installation failed
    GOTO :CLEANUP_ERROR
)
ECHO SUCCESS: Visual Studio has been installed successfully


:: Success cleanup
ECHO.
ECHO DONE: Visual Studio Code has been installed successfully!
ECHO.

GOTO :CLEANUP_SUCCESS


:CLEANUP_ERROR
ECHO.
ECHO ERROR: Visual Studio Code installation could not be completed!
ECHO.


:CLEANUP_SUCCESS
:: Clean up temporary files
IF EXIST "%VsCodeLocalInstaller%" (
	DEL /Q "%VsCodeLocalInstaller%" >nul 2>&1
)

IF DEFINED CLEANUP_ERROR (
	EXIT /B 1
) ELSE (
	EXIT /B 0
)