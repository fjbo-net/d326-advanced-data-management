:: © 2026 FJBO
::
:: Provisions the database objects (functions, tables, triggers and
:: stored procedures) required by the report in the PostgreSQL database.
::
:: PostgreSQL asks for the password of `PostgresUser` when it connects.
:: Set the `PGPASSWORD` environment variable beforehand to skip the prompt.

@ECHO off
SETLOCAL

SET "PostgresUser=postgres"
SET "Database=dvdrental"
SET "SqlDirectory=%~dp0sql"

SET "TransformFunctionScript=%SqlDirectory%\create-transform-function.sql"
SET "DetailedTableScript=%SqlDirectory%\create-detailed-table.sql"


:: Check if psql is available
ECHO.
ECHO [1/4] Checking if psql is available...
psql --version >nul 2>&1
IF ERRORLEVEL 1 (
	ECHO ERROR: psql is not available.
	ECHO Run `scripts\dev\setup-user-path.bat` and open a new terminal.
	GOTO :CLEANUP_ERROR
)
ECHO SUCCESS: psql is available


:: Verify the provisioning scripts exist
ECHO.
ECHO [2/4] Checking provisioning scripts...
IF NOT EXIST "%TransformFunctionScript%" (
	ECHO ERROR: Script `create-transform-function.sql` not found in the `sql` directory.
	GOTO :CLEANUP_ERROR
)
IF NOT EXIST "%DetailedTableScript%" (
	ECHO ERROR: Script `create-detailed-table.sql` not found in the `sql` directory.
	GOTO :CLEANUP_ERROR
)
ECHO SUCCESS: Provisioning scripts found


:: Create the data transformation functions
ECHO.
ECHO [3/4] Creating data transformation functions in `%Database%`...
psql -U "%PostgresUser%" -d "%Database%" -v ON_ERROR_STOP=1 -f "%TransformFunctionScript%"
IF ERRORLEVEL 1 (
	ECHO ERROR: Failed to create the data transformation functions.
	GOTO :CLEANUP_ERROR
)
ECHO SUCCESS: Data transformation functions created


:: Create the detailed table
:: Add further provisioning scripts (summary table, stored procedures) as new steps below.
ECHO.
ECHO [4/4] Creating detailed table in `%Database%`...
psql -U "%PostgresUser%" -d "%Database%" -v ON_ERROR_STOP=1 -f "%DetailedTableScript%"
IF ERRORLEVEL 1 (
	ECHO ERROR: Failed to create the detailed table.
	GOTO :CLEANUP_ERROR
)
ECHO SUCCESS: Detailed table created


:: Success
ECHO.
ECHO DONE: Database `%Database%` has been set up successfully!
ECHO.

EXIT /B 0


:CLEANUP_ERROR
ECHO.
ECHO ERROR: Database setup failed!
ECHO.

EXIT /B 1
