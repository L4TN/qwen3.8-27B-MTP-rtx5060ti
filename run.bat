@echo off
REM Qwen3.8-27B - RTX 5060 Ti - MTP
set LLAMA=C:\llamacpp\llama-server.exe
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}

if not exist "%LLAMA%" echo ERROR: %LLAMA% not found && pause && exit /b 1

nvidia-smi
echo ""
echo Select mode:
echo   [1] High Precision - IQ4_XS 45K Q8  (limite 15860 MiB 94/45 t/s) - Recommended
echo   [2] Extended Context - IQ3_XXS 160K Q4 (limite 15528 MiB 85/57 t/s, max 250K exp)
echo       Also validated: IQ4 Q4 90K limite 107/46, IQ3 Q8 100K limite 84/57, 32K/64K/100K/128K/148K market
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
set CTX=160000
set KVK=q4_0
set KVV=q4_0
echo Starting Extended Context 160K limit on http://127.0.0.1:1234

:run
if not exist "%MODEL%" echo ERROR: %MODEL% not found && pause && exit /b 1
"%LLAMA%" -m "%MODEL%" --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size %CTX% --parallel 1 --cache-type-k %KVK% --cache-type-v %KVV% --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234 -lv 4
pause
