@echo off
REM Qwen3.8-27B - RTX 5060 Ti - MTP
set LLAMA=C:\llamacpp\llama-server.exe
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}

if not exist "%LLAMA%" echo ERROR: %LLAMA% not found && pause && exit /b 1

nvidia-smi
echo ""
echo Select mode:
echo   [1] High Precision - IQ4_XS 45K Q8  (max quality, 47.9/37.1 t/s, 15.9GB) - Recommended
echo   [2] Extended Context - IQ3_XXS 150K Q4 (sweet spot 15.0GB, 38/49 t/s, max 250K fits)
echo       Also validated: IQ4 32K 15.5GB 52/44, IQ3 94K 13.5GB, 250K 15.5GB max
echo ""
set /p choice="Enter 1 or 2 (default 1): "
if "%choice%"=="2" goto canhao

:bisturi
set MODEL=C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf
set CTX=45056
set KVK=q8_0
set KVV=q8_0
echo Starting High Precision 45K on http://127.0.0.1:1234
goto run

:canhao
set MODEL=C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf
set CTX=150000
set KVK=q4_0
set KVV=q4_0
echo Starting Extended Context 150K on http://127.0.0.1:1234

:run
if not exist "%MODEL%" echo ERROR: %MODEL% not found && pause && exit /b 1
"%LLAMA%" -m "%MODEL%" --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size %CTX% --parallel 1 --cache-type-k %KVK% --cache-type-v %KVV% --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234 -lv 4
pause
