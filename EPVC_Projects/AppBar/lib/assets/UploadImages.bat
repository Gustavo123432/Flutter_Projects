@echo off
setlocal enabledelayedexpansion

:: API endpoint
set "API_URL=https://appbar.epvc.pt/API/appBarAPI_Post.php"

:: Directory containing images
set "IMAGE_DIR=C:\Users\gusfe\Downloads\d5499585-23c1-483a-be66-5a42f140159f"

:: Query parameter value
set "QUERY_PARAM=11"

:: Loop through all image files in the directory
for %%f in ("%IMAGE_DIR%\*.jpg" "%IMAGE_DIR%\*.jpeg" "%IMAGE_DIR%\*.png" "%IMAGE_DIR%\*.gif") do (
    echo Sending file: %%~nxf
    curl -X POST -F "query_param=%QUERY_PARAM%" -F "images=@%%f" "%API_URL%"
    echo.
)

echo All images have been processed.
pause