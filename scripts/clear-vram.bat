@echo off
REM Clear VRAM - kills llama-server and frees GPU memory
echo Checking GPU before...
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader
echo.
tasklist | findstr /i "llama-server" >nul
if %errorlevel%==0 (
  echo Found llama-server - killing...
  taskkill /F /IM llama-server.exe 2>nul
  timeout /t 3 >nul
  echo Killed.
) else (
  echo No llama-server running.
)
echo.
echo GPU after:
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader
nvidia-smi
echo VRAM cleared. You can now start another model.
pause
