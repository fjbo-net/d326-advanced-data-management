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


:: Download Visual Studio Code install script
ECHO.
ECHO [1/6] Downloading VS Code installer script...
CURL -L -o %VsCodeLocalInstallScript% %VsCodeInstallScriptUrl%


:: Download Git for Windows install script
ECHO.
ECHO [2/6] Downloading Git installer script...
CURL -L -o %GitLocalInstallerScript% %GitInstallerScriptUrl%


:: Run Visual Studio Code install script
ECHO.
ECHO [3/6] Installing VS Code...
"%VsCodeLocalInstallScript%"


:: Run Git for Windows install script
ECHO.
ECHO [4/6] Installing Git...
"%GitLocalInstallerScript%"


:: Clone repository
ECHO.
ECHO [5/6] Cloning repository...
"%Git%" clone %RepoGitUrl% %LocalRepo%


:: Open repository in Visual Studio Code
ECHO.
ECHO [6/6] Opening repository in VS Code...
CODE %LocalRepo%