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


:: Download Visual Studio Code install script
ECHO.
ECHO [2/7] Downloading VS Code installer script...
CURL -L -o %VsCodeLocalInstallScript% %VsCodeInstallScriptUrl%


:: Download Git for Windows install script
ECHO.
ECHO [3/7] Downloading Git installer script...
CURL -L -o %GitLocalInstallerScript% %GitInstallerScriptUrl%


:: Run Visual Studio Code install script
ECHO.
ECHO [4/7] Installing VS Code...
"%VsCodeLocalInstallScript%"


:: Run Git for Windows install script
ECHO.
ECHO [5/7] Installing Git...
"%GitLocalInstallerScript%"


:: Clone repository
ECHO.
ECHO [6/7] Cloning repository...
"%Git%" clone %RepoGitUrl% %LocalRepo%


:: Open repository in Visual Studio Code
ECHO.
ECHO [7/7] Opening repository in VS Code...
CODE %LocalRepo%