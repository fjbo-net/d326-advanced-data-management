:: © 2025 FJBO
::
:: Sets up development dependencies from remote scripts.

@ECHO off

SET UserDownloads=%USERPROFILE%\Downloads

SET RepoName=d326-advanced-data-management
SET RepoUrl=https://github.com/fjbo-net/%RepoName%
SET RepoGitUrl=%RepoUrl%.git
SET Head=11-add-dev-setup
SET DevScriptsBaseUrl=https://raw.githubusercontent.com/fjbo-net/%RepoName%/refs/heads/%Head%/scripts/dev
SET DevDirectory=%USERPROFILE%\Source
SET LocalRepo=%DevDirectory%\%RepoName%

SET VsCodeInstallScriptName=install-vscode.bat
SET VsCodeInstallScriptUrl=%DevScriptsBaseUrl%/%VsCodeInstallScriptName%
SET VsCodeLocalInstallScript=%UserDownloads%\%VsCodeInstallScriptName%

SET GitInstallerScriptName=install-git.bat
SET GitInstallerScriptUrl=%DevScriptsBaseUrl%/%GitInstallerScriptName%
SET GitLocalInstallerScript=%UserDownloads%\%GitInstallerScriptName%

SET GitDirectory=%ProgramFiles%\Git
SET GitBinDirectory=%GitDirectory%\bin
SET Git=%GitBinDirectory%\git.exe


:: Download Visual Studio Code install script
CURL -L -o %VsCodeLocalInstallScript% %VsCodeInstallScriptUrl%

:: Download Git for Windows install script
CURL -L -o %GitLocalInstallerScript% %GitInstallerScriptUrl%


:: Run Visual Studio Code install script
"%VsCodeLocalInstallScript%"

:: Run Git for Windows install script
"%GitLocalInstallerScript%"

:: Clone Repository
"%Git%" clone %RepoGitUrl% %LocalRepo%

CODE %LocalRepo%