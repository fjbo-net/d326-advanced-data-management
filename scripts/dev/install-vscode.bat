:: © 2025 FJBO
::
:: Downloads and installs Visual Studio Code 

@ECHO off

SET UserDownloads=%USERPROFILE%\Downloads

SET VsCodeInstallerCommit=488a1f239235055e34e673291fb8d8c810886f81
SET VsCodeInstallerFileName=VSCodeUserSetup-x64-1.102.3.exe
SET VsCodeInstallerUrl=https://vscode.download.prss.microsoft.com/dbazure/download/stable/%VsCodeInstallerCommit%/%VsCodeInstallerFileName%
SET VsCodeLocalInstaller=%UserDownloads%\%VsCodeInstallerFileName%

:: Download Visual Studio Code installer
CURL -L -o %VsCodeLocalInstaller% %VsCodeInstallerUrl%

:: Install Visual Studio Code
%VsCodeLocalInstaller% /VERYSILENT /SUPPRESSMSGBOXES /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders"