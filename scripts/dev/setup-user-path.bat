:: @ 2026 FJBO
::
:: Adds PostgreSQL bin directory to the user's `PATH` variable.

@ECHO off

:: PostgreSQL version provisioned in Lab
SET "PostgresVersion=13"
SET "PostgresInstallDir=C:\Program Files\PostgreSQL\%PostgresVersion%"
SET "PostgresBinDir=%PostgresInstallDir%\bin"

ECHO Checking if PostgreSQL bin directory exists: %PostgresBinDir%

IF NOT EXIST "%PostgresBinDir%" (
    ECHO ERROR: PostgreSQL `bin` directory not found at `%PostgresBinDir%`.
    GOTO :eof
)


ECHO Adding `%PostgresBinDir%` to user PATH...
:: Check if Bin directory already in user path
ECHO %PATH% | FINDSTR /I /L /C:"%PostgresBinDir%" >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO Adding `%PostgresBinDir%` to user path...
    
    SETX PATH "%PATH%;%PostgresBinDir%"
    IF ERRORLEVEL 1 (
        ECHO ERROR: Failed to add `%PostgresBinDir%` to user path.
    ) ELSE (
        ECHO `%PostgresBinDir%` has been added to user path.
    )
)