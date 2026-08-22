@echo off
REM Qwen3.8-27B UD-IQ4_XS + MTP - RTX 5060 Ti
REM Uso: duplo clique em run.bat

set LLAMA=C:\llamacpp\llama-server.exe
set MODEL=C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}

if not exist "%LLAMA%" echo ERRO: llama-server nao encontrado em %LLAMA% && pause && exit /b 1
if not exist "%MODEL%" echo ERRO: modelo nao encontrado em %MODEL% && pause && exit /b 1

nvidia-smi
echo Iniciando em http://127.0.0.1:1234
"%LLAMA%" -m "%MODEL%" --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 32768 --parallel 1 --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234 -lv 4
pause
