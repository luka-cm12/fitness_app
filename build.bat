@echo off
echo Building Flutter web app...
cd fitness_app
call flutter build web --release --web-renderer html

echo Moving build files to deployment location...
if not exist "..\deploy\web" mkdir "..\deploy\web"
xcopy "build\web\*" "..\deploy\web\" /E /Y

echo Build complete!