@echo off
setlocal EnableDelayedExpansion

:: Use the first argument as target folder, or current directory if none provided
if "%~1"=="" (
    set "TARGET_DIR=%CD%"
) else (
    set "TARGET_DIR=%~1"
)

:: Remove trailing backslash if present
if "%TARGET_DIR:~-1%"=="\" set "TARGET_DIR=%TARGET_DIR:~0,-1%"

if not exist "%TARGET_DIR%\" (
    echo Folder not found: "%TARGET_DIR%"
    pause
    exit /b 1
)

echo Organizing files in: "%TARGET_DIR%"
echo.

for %%F in ("%TARGET_DIR%\*") do (
    :: Skip directories and this batch script itself
    if /I not "%%~nxF"=="%~nx0" (
        if not exist "%%~F\" (
            set "EXT=%%~xF"
            if "!EXT!"=="" (
                set "FOLDER_NAME=NO_EXTENSION"
            ) else (
                set "FOLDER_NAME=!EXT:~1!"
            )

            set "DEST_DIR=%TARGET_DIR%\!FOLDER_NAME!"
            if not exist "!DEST_DIR!\" mkdir "!DEST_DIR!"

            set "FILENAME=%%~nF"
            set "DEST_FILE=!DEST_DIR!\%%~nxF"

            if not exist "!DEST_FILE!" (
                move /Y "%%~F" "!DEST_FILE!" >nul
                echo Moved: "%%~nxF" -^> "!FOLDER_NAME!\"
            ) else (
                call :GetTimestamp TS
                set "NEW_NAME=!FILENAME!_!TS!%%~xF"
                set "NEW_DEST=!DEST_DIR!\!NEW_NAME!"

                :: If a collision still happens within the same second, append a counter
                set /A CNT=1
                :UniqueLoop
                if exist "!NEW_DEST!" (
                    set "NEW_NAME=!FILENAME!_!TS!_!CNT!%%~xF"
                    set "NEW_DEST=!DEST_DIR!\!NEW_NAME!"
                    set /A CNT+=1
                    goto :UniqueLoop
                )

                move /Y "%%~F" "!NEW_DEST!" >nul
                echo Renamed & Moved: "%%~nxF" -^> "!FOLDER_NAME!\!NEW_NAME!"
            )
        )
    )
)

echo.
echo Done!
pause
exit /b 0

:GetTimestamp
setlocal
for /f "tokens=2 delims==" %%I in ('wmic os get LocalDateTime /value 2^>nul') do set "LDT=%%I"
if defined LDT (
    set "STAMP=%LDT:~0,8%_%LDT:~8,6%"
) else (
    :: Fallback if wmic is unavailable
    for /f "tokens=1-3 delims=/.- " %%A in ("%date%") do set "D1=%%A%%B%%C"
    for /f "tokens=1-3 delims=:. " %%A in ("%time: =0%") do set "T1=%%A%%B%%C"
    set "STAMP=%D1%_%T1%"
)
endlocal & set "%~1=%STAMP%"
goto :eof