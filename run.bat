@echo off
REM Qwen 3 27B - Menu Bisturi vs Canhao
set LLAMA=C:\llamacpp\llama-server.exe
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}

if not exist "%LLAMA%" echo ERRO: %LLAMA% nao encontrado && pause && exit /b 1

nvidia-smi
echo ""
echo Escolha o modo:
echo   [1] BISTURI - IQ4_XS 32K Q8  (precisao, 52 t/s) - Recomendado
echo   [2] CANHAO  - IQ3_XXS 94K Q4 (contexto gigante, 60 t/s)
echo ""
set /p choice="Digite 1 ou 2 (default 1): "
if "%choice%"=="2" goto canhao

:bisturi
set MODEL=C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf
set CTX=32768
set KVK=q8_0
set KVV=q8_0
echo Iniciando BISTURI em http://127.0.0.1:1234
goto run

:canhao
set MODEL=C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf
set CTX=94208
set KVK=q4_0
set KVV=q4_0
echo Iniciando CANHAO em http://127.0.0.1:1234

:run
if not exist "%MODEL%" echo ERRO: %MODEL% nao encontrado && pause && exit /b 1
"%LLAMA%" -m "%MODEL%" --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size %CTX% --parallel 1 --cache-type-k %KVK% --cache-type-v %KVV% --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234 -lv 4
pause
