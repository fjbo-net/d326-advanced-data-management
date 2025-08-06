:: © 2025 FJBO
::
:: Sets up development dependencies from remote scripts.

@ECHO off

SET "UserDownloads=%USERPROFILE%\Downloads"
SET "RepoName=d326-advanced-data-management"
SET "RepoUrl=https://github.com/fjbo-net/%RepoName%"
SET "RepoGitUrl=%RepoUrl%.git"
SET "Head=11-add-dev-setup"
SET "DevScriptsBaseUrl=https://raw.githubusercontent.com/fjbo-net/%RepoName%/refs/heads/%Head%/scripts/dev"
SET "DevDirectory=%USERPROFILE%\Source"
SET "LocalRepo=%DevDirectory%\%RepoName%"

SET "VsCodeInstallScriptName=install-vscode.bat"
SET "VsCodeInstallScriptUrl=%DevScriptsBaseUrl%/%VsCodeInstallScriptName%"
SET "VsCodeLocalInstallScript=%UserDownloads%\%VsCodeInstallScriptName%"

SET "GitInstallerScriptName=install-git.bat"
SET "GitInstallerScriptUrl=%DevScriptsBaseUrl%/%GitInstallerScriptName%"
SET "GitLocalInstallerScript=%UserDownloads%\%GitInstallerScriptName%"

SET "GitDirectory=%ProgramFiles%\Git"
SET "GitBinDirectory=%GitDirectory%\bin"
SET "Git=%GitBinDirectory%\git.exe"


:: Check if curl is available
ECHO.
ECHO [1/7] Checking if curl is available...
curl --version >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO ERROR: curl is not available. Cannot continue.
    EXIT /B 1
)
ECHO SUCCESS: curl is available


:: Download Visual Studio Code installer script
ECHO.
ECHO [2/7] Downloading VS Code installer script...
CURL -L -f -s -o "%VsCodeLocalInstallScript%" "%VsCodeInstallScriptUrl%"
IF ERRORLEVEL 1 (
	ECHO ERROR: Failed to download VS Code installer script.
	EXIT /B 1
)

:: Verify Visual Studio Code script was downloaded
IF NOT EXIST "%VsCodeLocalInstallScript%" (
	ECHO ERROR: VS Code installer script was not downloaded.
	EXIT /B 1
)

:: Verify Visual Studio Code has content
FOR %%A IN ("%VsCodeLocalInstallScript%") DO (
	IF %%~zA LSS 10 (
		ECHO ERROR: Downloaded VS Code script appears to be empty or corrupted.
		EXIT /B 1
	)
)
ECHO SUCCESS: VS Code installer script downloaded


:: Download Git for Windows install script
ECHO.
ECHO [3/7] Downloading Git installer script...
CURL -L -f -s -o "%GitLocalInstallerScript%" "%GitInstallerScriptUrl%"
IF ERRORLEVEL 1 (
	ECHO ERROR: Failed to download Git installer script.
	GOTO :CLEANUP_ERROR
)

:: Verify Git script was downloaded
IF NOT EXIST "%GitLocalInstallerScript%" (
	ECHO ERROR: Git installer script was not downloaded.
	GOTO :CLEANUP_ERROR
)

:: Verify Git script has content
FOR %%A IN ("%GitLocalInstallerScript%") DO (
	IF %%~zA LSS 10 (
		ECHO ERROR: Downloaded Git script appears to be empty or corrupted.
		GOTO :CLEANUP_ERROR
	)
)
ECHO SUCCESS: Git installer script downloaded


:: Run Visual Studio Code installer script
ECHO.
ECHO [4/7] Installing VS Code...
START /WAIT /B CMD /C ""%VsCodeLocalInstallScript%" >nul 2>&1"
IF ERRORLEVEL 1 (
	ECHO WARNING: VS Code installation may have failed.
) ELSE (
	ECHO SUCCESS: VS Code installation completed
)


:: Run Git for Windows installer script
ECHO.
ECHO [5/7] Installing Git...
START /WAIT /B CMD /C ""%GitLocalInstallerScript%" >nul 2>&1"
IF ERRORLEVEL 1 (
	ECHO WARNING: Git installation may have failed.
) ELSE (
	ECHO SUCCESS: Git installation completed
)


:: Clone repository
ECHO.
ECHO [6/7] Cloning repository...

:: Locate Git Executable
SET "GitFound="

ECHO - Locating Git executable...
ECHO -- Attempting system PATH...
GIT --version >nul 2>&1
IF NOT ERRORLEVEL 1 (
	SET "GitFound=GIT"
	ECHO Git has been located in the system 'PATH'
) ELSE (
	ECHO -- Attempting default installation path...
	IF EXIST "%Git%" (
		SET "GitFound="%Git%""
		ECHO Git has been located in the default installation path '%Git%'
	) ELSE (
		ECHO ERROR: Git executable not found.
		GOTO :CLEANUP_ERROR
	)
)
ECHO Found Git at: %GitFound%
ECHO - Attempting to clone repository into '%LocalRepo%'
"%GitFound%" clone %RepoGitUrl% "%LocalRepo%" >nul 2>&1
IF ERRORLEVEL 1 (
	ECHO ERROR: Failed to clone repository.
	GOTO :CLEANUP_ERROR
)
ECHO SUCCESS: Repository cloned successfully


:: Open repository in Visual Studio Code
ECHO.
ECHO [7/7] Opening repository in VS Code...
START "" CODE "%LocalRepo%" >nul 2>&1
IF ERRORLEVEL 1 (
	ECHO WARNING: Could not automatically open VS Code
	ECHO You can manually open: "%LocalRepo%"
) ELSE (
	ECHO SUCCESS: Repository opened in VS Code
)


:: Success cleanup
ECHO.
ECHO DONE: Setup completed successfully!
ECHO Repository location: "%LocalRepo%"
ECHO.

GOTO :CLEANUP_SUCCESS

:CLEANUP_ERROR
ECHO.
ECHO ERROR: Setup failed!
ECHO.

:CLEANUP_SUCCESS
:: Clean up temporary files
IF EXIST "%VsCodeLocalInstallScript%" (
	DEL /Q "%VsCodeLocalInstallScript%" >nul 2>&1
)
IF EXIST "%GitLocalInstallerScript%" (
	DEL /Q "%GitLocalInstallerScript%" >nul 2>&1
)

IF DEFINED CLEANUP_ERROR (
	EXIT /B 1
) ELSE (
	EXIT /B 0
)